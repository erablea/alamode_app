import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/services/auth_service.dart';
import 'package:alamode_app/view/legal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _signupPasswordConfirmCtrl = TextEditingController();
  final _signupNameCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureLogin = true;
  bool _obscureSignup = true;
  bool _obscureSignupConfirm = true;
  bool _agreedToTerms = false;
  String? _loginError;
  String? _signupError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {
      _loginError = null;
      _signupError = null;
    }));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _signupPasswordConfirmCtrl.dispose();
    _signupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmailCtrl.text.trim().isEmpty || _loginPasswordCtrl.text.isEmpty) {
      setState(() => _loginError = 'メールアドレスとパスワードを入力してください');
      return;
    }
    setState(() { _isLoading = true; _loginError = null; });
    try {
      await AuthService.instance.signIn(_loginEmailCtrl.text, _loginPasswordCtrl.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _loginError = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_signupNameCtrl.text.trim().isEmpty) {
      setState(() => _signupError = 'お名前を入力してください');
      return;
    }
    if (_signupEmailCtrl.text.trim().isEmpty) {
      setState(() => _signupError = 'メールアドレスを入力してください');
      return;
    }
    if (_signupPasswordCtrl.text.length < 10) {
      setState(() => _signupError = 'パスワードは10文字以上で入力してください');
      return;
    }
    if (_signupPasswordCtrl.text != _signupPasswordConfirmCtrl.text) {
      setState(() => _signupError = 'パスワードが一致しません');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _signupError = '利用規約とプライバシーポリシーに同意してください');
      return;
    }
    setState(() { _isLoading = true; _signupError = null; });
    try {
      await AuthService.instance.signUp(
        _signupEmailCtrl.text,
        _signupPasswordCtrl.text,
        _signupNameCtrl.text,
      );
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Text(
              '確認メールを送信しました。\nメールを確認してからログインしてください。',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(_);
                  _tabController.animateTo(0);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _signupError = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _loginEmailCtrl.text);
    String? error;
    bool sending = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('パスワードを忘れた方'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ご登録のメールアドレスを入力してください。パスワード再設定用のメールをお送りします。',
                    style: TextStyle(fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: AppColors.errorColor, fontSize: 13)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (emailCtrl.text.trim().isEmpty) {
                            setDialogState(() => error = 'メールアドレスを入力してください');
                            return;
                          }
                          setDialogState(() { sending = true; error = null; });
                          try {
                            await AuthService.instance.resetPassword(emailCtrl.text);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('パスワード再設定用のメールを送信しました')),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              sending = false;
                              error = _parseError(e.toString());
                            });
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('送信', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _parseError(String error) {
    if (error.contains('Invalid login credentials')) return 'メールアドレスまたはパスワードが正しくありません';
    if (error.contains('Email not confirmed')) return 'メールアドレスの確認が完了していません';
    if (error.contains('User already registered')) return 'このメールアドレスはすでに登録されています';
    if (error.contains('Password should be')) return 'パスワードは10文字以上で入力してください';
    if (error.contains('rate limit')) return 'しばらく時間をおいてから再試行してください';
    return 'エラーが発生しました。もう一度お試しください。';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text('アカウント', style: TextStyle(color: primary)),
        iconTheme: IconThemeData(color: primary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: AppColors.blackLight,
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'ログイン'),
            Tab(text: '新規登録'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLoginTab(), _buildSignupTab()],
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildTextField(_loginEmailCtrl, 'メールアドレス', Icons.email_outlined, false),
          const SizedBox(height: 16),
          _buildTextField(
            _loginPasswordCtrl, 'パスワード', Icons.lock_outline, _obscureLogin,
            toggle: () => setState(() => _obscureLogin = !_obscureLogin),
          ),
          if (_loginError != null) ...[
            const SizedBox(height: 10),
            Text(_loginError!, style: const TextStyle(color: AppColors.errorColor, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('ログイン', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : _showForgotPasswordDialog,
            child: Text(
              'パスワードを忘れた方',
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          _buildNote(),
        ],
      ),
    );
  }

  Widget _buildSignupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildTextField(_signupNameCtrl, 'ユーザー名（後から変更可能です）', Icons.person_outline, false),
          const SizedBox(height: 16),
          _buildTextField(_signupEmailCtrl, 'メールアドレス', Icons.email_outlined, false),
          const SizedBox(height: 16),
          _buildTextField(
            _signupPasswordCtrl, 'パスワード（10文字以上）', Icons.lock_outline, _obscureSignup,
            toggle: () => setState(() => _obscureSignup = !_obscureSignup),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _signupPasswordConfirmCtrl, 'パスワード（確認）', Icons.lock_outline, _obscureSignupConfirm,
            toggle: () => setState(() => _obscureSignupConfirm = !_obscureSignupConfirm),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  activeColor: Theme.of(context).primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: AppColors.blackLight, height: 1.5),
                    children: [
                      TextSpan(
                        text: '利用規約',
                        style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
                      ),
                      const TextSpan(text: 'と'),
                      TextSpan(
                        text: 'プライバシーポリシー',
                        style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                      ),
                      const TextSpan(text: 'に同意する'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_signupError != null) ...[
            const SizedBox(height: 10),
            Text(_signupError!, style: const TextStyle(color: AppColors.errorColor, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _signup,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('アカウントを作成', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 24),
          _buildNote(),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return const Text(
      'ログインすると、アプリやお使いのスマートフォンの不具合の際もデータが維持できます。機種変更時のデータ引き継ぎも可能です。',
      style: TextStyle(fontSize: 12, color: AppColors.blackLight, height: 1.6),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool obscure, {
    VoidCallback? toggle,
  }) {
    final primary = Theme.of(context).primaryColor;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: label.contains('メール') ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.blackLight, size: 20),
        suffixIcon: toggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.blackLight),
                onPressed: toggle,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.inputBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.inputBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primary, width: 2)),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AppColors.blackLight, fontSize: 14),
      ),
    );
  }
}

class LoginPromptDialog extends StatefulWidget {
  const LoginPromptDialog({super.key});

  @override
  State<LoginPromptDialog> createState() => _LoginPromptDialogState();
}

class _LoginPromptDialogState extends State<LoginPromptDialog> {
  bool _neverShow = false;

  Future<void> _dismiss({bool goLogin = false}) async {
    if (_neverShow) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('login_popup_dismissed', true);
    }
    if (mounted) Navigator.of(context).pop(goLogin ? 'login' : null);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Dialog(
      backgroundColor: AppColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/others.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _dismiss(goLogin: true),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('ログイン / 新規登録', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _dismiss(),
                  child: const Text('あとで', style: TextStyle(color: AppColors.blackLight, fontSize: 13)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ログインすると、アプリやお使いのスマートフォンの不具合の際もデータが維持できます。',
                  style: TextStyle(fontSize: 11, color: AppColors.blackLight, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _neverShow,
                        onChanged: (v) => setState(() => _neverShow = v ?? false),
                        activeColor: primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('今後表示しない', style: TextStyle(fontSize: 12, color: AppColors.blackLight)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20, color: AppColors.blackLight),
              onPressed: () => _dismiss(),
              tooltip: '閉じる',
            ),
          ),
        ],
      ),
    );
  }
}
