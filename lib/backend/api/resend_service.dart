// lib/services/resend_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResendService {
  static final _apiKey  = dotenv.env['RESEND_API_KEY']!;
  static final _baseUrl = Uri.parse('https://api.resend.com/emails');

  /// Send a generic email via Resend
  //static Future<http.Response> sendEmail({ /*…*/ }) { /* existing code */ }

  /// Send a verification code to [email] with the given [code].
  static Future<http.Response> sendVerificationCode({
    required String email,
    required String code,
  }) {
    final body = {
      'from': 'no-reply@yourdomain.com',
      'to': [email],
      'subject': 'Your verification code',
      'html': '<p>Your verification code is <strong>$code</strong>.</p>',
      'text': 'Your verification code is $code.',
    };

    return http.post(
      _baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    );
  }
}
