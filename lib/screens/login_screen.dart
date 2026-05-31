import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;

  String _message(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'This email is already registered — use Login instead.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts — wait a few minutes and try again.';
      default:
        return 'Authentication error: $code';
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _saveProfile(User? user, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', username);
    await prefs.setString('token', user?.uid ?? 'firebase');
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      )).user;
      await _saveProfile(
        user,
        user?.displayName ?? user?.email?.split('@').first ?? 'EcoScanner',
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_message(e.code));
    } catch (e) {
      _showMessage('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showMessage('Please choose a username.');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showMessage('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = (await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      )).user;
      await user?.updateDisplayName(username);
      await _saveProfile(user, username);
    } on FirebaseAuthException catch (e) {
      _showMessage(_message(e.code));
    } catch (e) {
      _showMessage('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: MyApp.ecoGreen),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.ecoBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, size: 80, color: MyApp.ecoGreen),
                const SizedBox(height: 12),
                const Text(
                  'EcoScan Madrid',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: MyApp.ecoGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRegister ? 'Create your account' : 'Iniciar sesión',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 28),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (_isRegister) ...[
                          _field(_usernameController, 'Username', Icons.person),
                          const SizedBox(height: 16),
                        ],
                        _field(_emailController, 'Email', Icons.email,
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _field(_passwordController, 'Password', Icons.lock,
                            obscure: true),
                        if (_isRegister) ...[
                          const SizedBox(height: 16),
                          _field(_confirmController, 'Confirm password',
                              Icons.lock_outline,
                              obscure: true),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : (_isRegister ? _register : _login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyApp.ecoGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isRegister ? 'Create account' : 'Login',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister
                        ? 'Already have an account? Login'
                        : 'No account? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
