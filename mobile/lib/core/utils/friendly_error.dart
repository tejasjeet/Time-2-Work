import '../network/api_exception.dart';

String friendlyError(Object error) {
  if (error is ApiException) {
    final msg = error.message.trim();
    if (msg.isNotEmpty && !msg.startsWith('{')) return msg;
  }

  final raw = error.toString();
  if (raw.contains('Too many OTP') || raw.contains('RATE_LIMIT')) {
    return 'Too many OTP tries. Please wait 15 minutes and try again.';
  }
  if (raw.contains('Cannot reach server') || raw.contains('connection')) {
    return 'No internet or app service unavailable. Check your connection and try again.';
  }
  if (raw.contains('Login succeeded but no token')) return 'Login failed to finish. Please try again.';
  if (raw.contains('Invalid OTP') || raw.contains('OTP expired')) return 'Invalid or expired OTP. Please try again.';
  if (raw.contains('Exception: ')) {
    final cleaned = raw.replaceFirst('Exception: ', '').trim();
    if (cleaned.length <= 120 && !cleaned.startsWith('{')) return cleaned;
  }
  if (raw.length > 120 || raw.startsWith('{')) return 'Something went wrong. Please try again.';
  return raw;
}

bool looksLikeObjectId(String value) {
  final v = value.trim();
  return RegExp(r'^[a-f0-9]{24}$', caseSensitive: false).hasMatch(v);
}
