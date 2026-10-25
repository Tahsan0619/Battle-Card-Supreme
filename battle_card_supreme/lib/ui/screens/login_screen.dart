import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/session_controller.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/card_art.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registerMode = false;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final session = ref.read(sessionProvider.notifier);
    if (_registerMode) {
      await session.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
    } else {
      await session.login(
        email: _email.text.trim(),
        password: _password.text,
      );
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    final value = ref.read(sessionProvider).value;
    if (value?.isAuthenticated == true) {
      widget.onSuccess();
    } else if (value?.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value!.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(title: const Text('COMMANDER ACCESS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: BrandLogo(height: 120)),
          const SizedBox(height: 16),
          Text(
            _registerMode ? 'Create Rift account' : 'Sign in for online clashes',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'API: $kDefaultApiBaseUrl\nAndroid emulator uses 10.0.2.2 to reach host localhost.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AetheriumColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_registerMode)
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Commander name'),
            ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting || (session?.busy ?? false) ? null : _submit,
            child: Text(_registerMode ? 'REGISTER' : 'LOGIN'),
          ),
          TextButton(
            onPressed: _submitting
                ? null
                : () => setState(() => _registerMode = !_registerMode),
            child: Text(
              _registerMode
                  ? 'Already enlisted? Sign in'
                  : 'New commander? Register',
            ),
          ),
        ],
      ),
    );
  }
}
