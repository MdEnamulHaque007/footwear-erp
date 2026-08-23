import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;
  FirebaseStorage get instance => _storage;
}
