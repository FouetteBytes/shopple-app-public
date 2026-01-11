// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Quick test to verify JWT token generation matches Stream Chat requirements
void main() {
  const apiSecret =
      "64k7wudc6vps486zpbw84mmg5es2qcupyhyxajztjpebu2wtx9w3hsp78d6guruh";
  const userId = "QJz1hD70m2MfuTJW4n3nBWzffvx2";

  // Header
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final encodedHeader = base64Url.encode(utf8.encode(json.encode(header)));

  // Payload with the user ID
  final payload = {'user_id': userId};
  final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));

  // Create signature
  final message = '$encodedHeader.$encodedPayload';
  final hmac = Hmac(sha256, utf8.encode(apiSecret));
  final digest = hmac.convert(utf8.encode(message));
  final signature = base64Url.encode(digest.bytes);

  // Return the JWT token
  final token = '$encodedHeader.$encodedPayload.$signature';

  print('Generated JWT Token: $token');
  // print('Header: $header');
  // print('Payload: $payload');
  // print('Signature: $signature');
  // print('Computed Signature: $computedSignature');

  // Decode and verify
  final decodedHeader = utf8.decode(base64Url.decode(encodedHeader));
  final decodedPayload = utf8.decode(base64Url.decode(encodedPayload));

  print('Decoded Header: $decodedHeader');
  print('Decoded Payload: $decodedPayload');
}
