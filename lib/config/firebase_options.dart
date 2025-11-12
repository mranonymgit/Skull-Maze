import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAKr7dJfacQabE078me9_8OmQT9FvK6ees',
    appId: '1:69778184117:web:5eb53a280db178be746bfc',
    messagingSenderId: '69778184117',
    projectId: 'proyecto-e519b',
    authDomain: 'proyecto-e519b.firebaseapp.com',
    storageBucket: 'proyecto-e519b.firebasestorage.app',
    measurementId: 'G-7WNJKJX9KM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEq6mEtKdaVq_FUYPD8pL-VGImxmCZIL8',
    appId: '1:69778184117:android:e2d937e7cec8b067746bfc',
    messagingSenderId: '69778184117',
    projectId: 'proyecto-e519b',
    storageBucket: 'proyecto-e519b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCJjYSKKMgosxdLxKV172tf6psA8EsOAgg',
    appId: '1:69778184117:ios:8fda1b69fb612e7c746bfc',
    messagingSenderId: '69778184117',
    projectId: 'proyecto-e519b',
    storageBucket: 'proyecto-e519b.firebasestorage.app',
    iosBundleId: 'com.example.skullMaze',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCJjYSKKMgosxdLxKV172tf6psA8EsOAgg',
    appId: '1:69778184117:ios:8fda1b69fb612e7c746bfc',
    messagingSenderId: '69778184117',
    projectId: 'proyecto-e519b',
    storageBucket: 'proyecto-e519b.firebasestorage.app',
    iosBundleId: 'com.example.skullMaze',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAKr7dJfacQabE078me9_8OmQT9FvK6ees',
    appId: '1:69778184117:web:23e423a89afa5c78746bfc',
    messagingSenderId: '69778184117',
    projectId: 'proyecto-e519b',
    authDomain: 'proyecto-e519b.firebaseapp.com',
    storageBucket: 'proyecto-e519b.firebasestorage.app',
    measurementId: 'G-2JZF05RECT',
  );
}
