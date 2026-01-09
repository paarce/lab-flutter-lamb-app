// Firebase Web Configuration
// TODO: Reemplazar con valores reales de Firebase Console
// Ir a: Firebase Console → Project Settings → Your apps → Web app → SDK setup and configuration

const firebaseConfig = {
  apiKey: "AIzaSyAjBcvvyq2PZfrvvbSfDV9GVNcavGuOVlY",
  authDomain: "lamb-dev-36c91.firebaseapp.com",
  projectId: "lamb-dev-36c91",
  storageBucket: "lamb-dev-36c91.firebasestorage.app",
  messagingSenderId: "384054654746",
  appId: "1:384054654746:web:58e8f8fd1da6d621175ea3"
};

// Inicializar Firebase
firebase.initializeApp(firebaseConfig);

console.log('🔥 Firebase inicializado para cliente web');
