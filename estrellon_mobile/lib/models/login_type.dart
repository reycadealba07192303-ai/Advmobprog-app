enum LoginType {
  mongo,
  firebase,
}

extension LoginTypeX on LoginType {
  String get label => this == LoginType.mongo ? 'MongoDB' : 'Firebase';

  String get storageValue => name;

  static LoginType from(String? value) {
    if (value == LoginType.firebase.storageValue) {
      return LoginType.firebase;
    }
    return LoginType.mongo;
  }
}
