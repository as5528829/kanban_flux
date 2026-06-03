import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_snackbar.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../controllers/auth_controller.dart';
import '../utils/auth_validators.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true; // 用來切換「登入」或「註冊」模式
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLoginMode) {
        await ref.read(authControllerProvider.notifier).login(email, password);
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .register(email, password);
        showAppSnackBar('註冊成功！請查看驗證信或直接嘗試登入');
      }
    } on AuthFailure catch (e) {
      showAppSnackBar(e.message, isError: true);
    } catch (e) {
      showAppSnackBar('操作失敗，請稍後再試。', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重設密碼'),
          content: TextFormField(
            controller: resetEmailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              helperText: '我們會寄送密碼重設連結到這個信箱',
              border: OutlineInputBorder(),
            ),
            onFieldSubmitted: (_) {
              Navigator.pop(context, resetEmailController.text.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, resetEmailController.text.trim());
              },
              child: const Text('寄送'),
            ),
          ],
        );
      },
    ).whenComplete(resetEmailController.dispose);

    if (email == null) return;

    final emailError = validateEmail(email);
    if (emailError != null) {
      showAppFeedback(emailError, type: AppFeedbackType.warning);
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(email.trim());
      showAppSnackBar('密碼重設信已寄出，請查看你的 Email。');
    } on AuthFailure catch (e) {
      showAppSnackBar(e.message, isError: true);
    } catch (_) {
      showAppSnackBar('重設密碼信寄送失敗，請稍後再試。', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400, // 限制最大寬度，這樣在 Web/電腦版看也很精美
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isLoginMode ? '歡迎回來 Kanban Flux' : '建立全新帳號',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密碼',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: validatePassword,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLoginMode ? '登入' : '註冊'),
                ),
                if (_isLoginMode) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text('忘記密碼？'),
                  ),
                ],
                TextButton(
                  onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(_isLoginMode ? '還沒有帳號？點此註冊' : '已經有帳號了？點此登入'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
