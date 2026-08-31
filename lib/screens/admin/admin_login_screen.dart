import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = true; // Start loading to check session
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _verifyAdminClaimAndNavigate(user);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAdminClaimAndNavigate(User user) async {
    try {
      // Force refresh the token to get latest claims
      final idTokenResult = await user.getIdTokenResult(true);
      final role = idTokenResult.claims?['role'];
      
      if (role == 'admin') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        // Valid Firebase user, but not an admin
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() => _isLoading = false);
          _showGenericError();
        }
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() => _isLoading = false);
        _handleException(e);
      }
    }
  }

  void _showGenericError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login failed')),
    );
  }

  void _handleException(dynamic e) {
    if (e is FirebaseAuthException && e.code == 'network-request-failed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your connection')),
      );
    } else {
      _showGenericError();
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _verifyAdminClaimAndNavigate(userCredential.user!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _handleException(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 48,
                  color: AppTheme.darkAccent,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _isObscured = !_isObscured);
                      },
                    ),
                  ),
                  obscureText: _isObscured,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
