import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamb/errors/app_error.dart';
import 'package:lamb/errors/error_category.dart';
import 'package:lamb/errors/error_codes.dart';
import 'package:lamb/providers/image_reader_provider.dart';
import 'package:lamb/services/gallery_service.dart';

import '../helpers/image_reader_fakes.dart';

void main() {
  const dwell = Duration(seconds: 2);
  final bytes = Uint8List.fromList([1, 2, 3]);

  late FakeGalleryService gallery;
  late FakeVisionService vision;
  late FakeTTSService tts;

  ImageReaderProvider buildProvider({int pageSize = 50}) => ImageReaderProvider(
        gallery: gallery,
        vision: vision,
        tts: tts,
        dwellDuration: dwell,
        pageSize: pageSize,
      );

  setUp(() {
    gallery = FakeGalleryService(count: 3, bytes: bytes);
    vision = FakeVisionService();
    tts = FakeTTSService();
  });

  group('initialize', () {
    test('loads images and becomes ready when permission is granted', () {
      fakeAsync((async) {
        final provider = buildProvider();
        provider.initialize();
        async.flushMicrotasks();

        expect(provider.status, ImageReaderStatus.ready);
        expect(provider.images.length, 3);
        expect(provider.currentIndex, 0);
        expect(provider.hasLimitedAccess, isFalse);
      });
    });

    test('flags limited access (Android 14+ "selected photos")', () {
      fakeAsync((async) {
        gallery.permission = GalleryPermission.limited;
        final provider = buildProvider();
        provider.initialize();
        async.flushMicrotasks();

        expect(provider.status, ImageReaderStatus.ready);
        expect(provider.hasLimitedAccess, isTrue);
      });
    });

    test('publishes a non-retryable error when permission is denied', () {
      fakeAsync((async) {
        gallery.permission = GalleryPermission.denied;
        final provider = buildProvider();
        provider.initialize();
        async.flushMicrotasks();

        expect(provider.status, ImageReaderStatus.permissionDenied);
        final error = provider.takePendingError();
        expect(error!.code, ErrorCodes.galleryPermissionDenied);
        expect(error.canRetry, isFalse);
        expect(provider.takePendingError(), isNull, reason: 'error is consumed');
      });
    });

    test('is empty when the gallery has no photos', () {
      fakeAsync((async) {
        gallery = FakeGalleryService(count: 0, bytes: bytes);
        final provider = buildProvider();
        provider.initialize();
        async.flushMicrotasks();

        expect(provider.status, ImageReaderStatus.empty);
      });
    });
  });

  group('dwell-to-read', () {
    test('does not call the AI before the dwell time', () {
      fakeAsync((async) {
        final provider = buildProvider();
        provider.initialize();
        async.elapse(const Duration(milliseconds: 1900));

        expect(vision.calls, 0);
        expect(provider.currentAnalysis.state, AnalysisState.idle);
      });
    });

    test('reads the photo aloud after the dwell time', () {
      fakeAsync((async) {
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell + const Duration(milliseconds: 1));

        expect(vision.calls, 1);
        expect(provider.currentAnalysis.state, AnalysisState.done);
        expect(provider.currentAnalysis.description!.spokenText, 'Descripción 1');
        expect(tts.spoken, contains('Leyendo la foto, un momento.'));
        expect(tts.spoken.last, 'Descripción 1');
        expect(provider.isSpeaking, isTrue);
      });
    });

    test('swiping before the dwell time cancels the reading', () {
      fakeAsync((async) {
        final provider = buildProvider();
        provider.initialize();
        async.elapse(const Duration(seconds: 1));
        provider.onPageChanged(1);
        async.elapse(const Duration(milliseconds: 1500));

        // 2.5 s en total, pero solo 1.5 s en la foto 1
        expect(vision.calls, 0);

        async.elapse(const Duration(milliseconds: 600));
        expect(vision.calls, 1);
        expect(provider.analysisFor(provider.images[0]).state, AnalysisState.idle);
        expect(provider.analysisFor(provider.images[1]).state, AnalysisState.done);
      });
    });

    test('returning to an already read photo reuses the cached description', () {
      fakeAsync((async) {
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell);
        expect(vision.calls, 1);

        provider.onPageChanged(1);
        async.elapse(dwell);
        expect(vision.calls, 2);

        provider.onPageChanged(0);
        async.elapse(dwell);

        expect(vision.calls, 2, reason: 'no new AI call for a cached photo');
        expect(tts.spoken.last, 'Descripción 1');
      });
    });

    test('changing photo stops the current speech', () {
      fakeAsync((async) {
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell);
        expect(provider.isSpeaking, isTrue);

        provider.onPageChanged(1);
        async.flushMicrotasks();

        expect(tts.stops, greaterThan(0));
        expect(provider.isSpeaking, isFalse);
      });
    });

    test('a late AI response is cached but not spoken if the user moved on', () {
      fakeAsync((async) {
        vision = FakeVisionService(manual: true);
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell);
        expect(provider.currentAnalysis.state, AnalysisState.analyzing);

        provider.onPageChanged(1);
        vision.pending.first.complete(FakeVisionService.describe(1));
        async.flushMicrotasks();

        expect(tts.spoken, isNot(contains('Descripción 1')));
        expect(
          provider.analysisFor(provider.images[0]).state,
          AnalysisState.done,
        );
      });
    });

    test('readCurrentNow skips the dwell wait', () {
      fakeAsync((async) {
        final provider = buildProvider();
        provider.initialize();
        async.flushMicrotasks();

        provider.readCurrentNow();
        async.flushMicrotasks();

        expect(vision.calls, 1);
        async.elapse(dwell);
        expect(vision.calls, 1, reason: 'dwell timer was cancelled');
      });
    });
  });

  group('errors (no automatic retries)', () {
    test('retryable error is published and the photo is not retried alone', () {
      fakeAsync((async) {
        vision.error = AppError(
          category: ErrorCategory.llm,
          code: ErrorCodes.visionRequestFailed,
          userMessage: '',
          canRetry: true,
        );
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell);

        expect(provider.currentAnalysis.state, AnalysisState.failed);
        expect(provider.takePendingError()!.code, ErrorCodes.visionRequestFailed);
        expect(provider.autoReadEnabled, isTrue);

        // Volver a la misma foto no reintenta automáticamente
        provider.onPageChanged(1);
        async.elapse(const Duration(milliseconds: 100));
        provider.onPageChanged(0);
        async.elapse(dwell * 2);
        expect(vision.calls, 1);
      });
    });

    test('retryCurrent asks the AI again', () {
      fakeAsync((async) {
        vision.error = AppError(
          category: ErrorCategory.llm,
          code: ErrorCodes.visionRequestFailed,
          userMessage: '',
          canRetry: true,
        );
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell);
        expect(vision.calls, 1);

        vision.error = null;
        provider.retryCurrent();
        async.flushMicrotasks();

        expect(vision.calls, 2);
        expect(provider.currentAnalysis.state, AnalysisState.done);
      });
    });

    test('configuration error pauses auto-reading for the next photos', () {
      fakeAsync((async) {
        vision.error = AppError(
          category: ErrorCategory.llm,
          code: ErrorCodes.visionApiKeyMissing,
          userMessage: '',
          canRetry: false,
        );
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell);

        expect(provider.takePendingError()!.code, ErrorCodes.visionApiKeyMissing);
        expect(provider.autoReadEnabled, isFalse);

        provider.onPageChanged(1);
        async.elapse(dwell * 2);
        expect(vision.calls, 1, reason: 'no repeated error dialogs per photo');
        expect(provider.takePendingError(), isNull);
      });
    });

    test('photo deleted from the gallery fails gracefully', () {
      fakeAsync((async) {
        gallery = FakeGalleryService(count: 3, bytes: null);
        final provider = buildProvider();
        provider.initialize();
        async.elapse(dwell);

        expect(vision.calls, 0);
        expect(provider.currentAnalysis.state, AnalysisState.failed);
        expect(provider.takePendingError()!.code, ErrorCodes.galleryLoadFailed);
      });
    });
  });

  group('pagination', () {
    test('loads the next page when approaching the end', () {
      fakeAsync((async) {
        gallery = FakeGalleryService(count: 25, bytes: bytes);
        final provider = buildProvider(pageSize: 10);
        provider.initialize();
        async.flushMicrotasks();
        expect(provider.images.length, 10);

        provider.onPageChanged(6); // 10 - 5 (loadMoreThreshold) = 5
        async.flushMicrotasks();

        expect(gallery.requestedPages, [0, 1]);
        expect(provider.images.length, 20);
      });
    });

    test('stops requesting pages after a short page', () {
      fakeAsync((async) {
        gallery = FakeGalleryService(count: 12, bytes: bytes);
        final provider = buildProvider(pageSize: 10);
        provider.initialize();
        async.flushMicrotasks();

        provider.onPageChanged(6);
        async.flushMicrotasks();
        expect(provider.images.length, 12);

        provider.onPageChanged(11);
        async.flushMicrotasks();
        expect(gallery.requestedPages, [0, 1]);
      });
    });
  });

  test('dispose releases the vision service and stops speech', () {
    fakeAsync((async) {
      final provider = buildProvider();
      provider.initialize();
      async.elapse(dwell);
      expect(provider.isSpeaking, isTrue);

      provider.dispose();
      async.flushMicrotasks();

      expect(vision.disposed, isTrue);
      expect(tts.stops, greaterThan(0));
    });
  });
}
