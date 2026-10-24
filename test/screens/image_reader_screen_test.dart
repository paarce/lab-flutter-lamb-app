import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamb/config/image_reader_config.dart';
import 'package:lamb/screens/image_reader_screen.dart';
import 'package:lamb/services/gallery_service.dart';
import 'package:lamb/services/tts/tts_service.dart';
import 'package:provider/provider.dart';

import '../helpers/image_reader_fakes.dart';

void main() {
  late FakeGalleryService gallery;
  late FakeVisionService vision;
  late FakeTTSService tts;

  setUp(() {
    // Bytes que no son una imagen real: el visor muestra el icono de foto
    // no disponible, pero la IA (fake) puede "leerlos"
    gallery = FakeGalleryService(count: 3, bytes: Uint8List.fromList([1, 2, 3]));
    vision = FakeVisionService();
    tts = FakeTTSService();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<TTSService>.value(
        value: tts,
        child: MaterialApp(
          home: ImageReaderScreen(
            galleryService: gallery,
            visionService: vision,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the first photo with position and accessible controls',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Foto 1 de 3'), findsOneWidget);
    expect(find.text('Quédate en esta foto y te la leeré.'), findsOneWidget);
    expect(find.bySemanticsLabel('Anterior'), findsOneWidget);
    expect(find.bySemanticsLabel('Siguiente'), findsOneWidget);
    expect(find.bySemanticsLabel('Leer foto'), findsOneWidget);

    // Desmontar antes de que salte el timer de permanencia
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('control buttons are at least 80dp tall', (tester) async {
    await pumpScreen(tester);

    final size = tester.getSize(find.widgetWithText(ElevatedButton, 'Siguiente'));
    expect(size.height, greaterThanOrEqualTo(80));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reads the photo after the dwell time and shows the description',
      (tester) async {
    await pumpScreen(tester);

    await tester.pump(ImageReaderConfig.dwellDuration);
    await tester.pump();

    expect(find.text('Descripción 1'), findsOneWidget);
    expect(find.text('Fotografía'), findsOneWidget);
    expect(tts.spoken.last, 'Descripción 1');
    // Mientras habla, el botón central permite detener la lectura
    expect(find.bySemanticsLabel('Detener'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Siguiente" moves to the next photo', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Foto 2 de 3'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hide-text button shows the photo without the panel',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsLabel('Ocultar texto'));
    await tester.pump();

    expect(find.text('Quédate en esta foto y te la leeré.'), findsNothing);
    expect(find.bySemanticsLabel('Mostrar texto'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows settings shortcut when permission is denied',
      (tester) async {
    gallery.permission = GalleryPermission.denied;
    await pumpScreen(tester);
    // Cerrar el diálogo de error accesible
    await tester.pumpAndSettle();
    if (find.text('Cerrar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Necesito permiso para ver tus fotos.'), findsOneWidget);

    await tester.tap(find.text('Abrir configuración'));
    expect(gallery.settingsOpened, 1);
  });
}
