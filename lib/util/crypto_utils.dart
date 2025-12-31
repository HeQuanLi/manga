import 'package:encrypt/encrypt.dart';

String decryptData(String encryptedData, {required String key, required String iv}) {
  try {
    final keyBytes = Key.fromUtf8(key);
    final ivBytes = IV.fromUtf8(iv);
    final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc));

    final encrypted = Encrypted.fromBase64(encryptedData);
    final decrypted = encrypter.decrypt(encrypted, iv: ivBytes);

    return decrypted;
  } catch (e) {
    throw Exception('Failed to decrypt data: $e');
  }
}

String getDefaultDomain() {
  return 'https://www.mxdm.tv';
}
