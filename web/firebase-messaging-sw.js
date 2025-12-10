// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCm5N4cHPdP7MfO_z0xCFYh6V0ZNRjWbqU",
  authDomain: "cattle-tracker-17c4c.firebaseapp.com",
  projectId: "cattle-tracker-17c4c",
  storageBucket: "cattle-tracker-17c4c.firebasestorage.app",
  messagingSenderId: "1039765268462",
  appId: "1:1039765268462:web:8ddd335e86ff15caa210ff"
});

const messaging = firebase.messaging();