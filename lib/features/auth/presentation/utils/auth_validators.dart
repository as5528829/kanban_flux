String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return '請輸入 Email';
  if (email.contains(RegExp(r'\s'))) return 'Email 不能包含空白';

  final emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
    r"(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );

  return emailRegex.hasMatch(email) ? null : '請輸入有效的 Email 格式';
}

String? validatePassword(String? value) {
  final password = value?.trim() ?? '';
  return password.length < 6 ? '密碼長度至少需 6 位數' : null;
}
