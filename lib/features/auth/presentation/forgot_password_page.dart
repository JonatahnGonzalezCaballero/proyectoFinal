import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../application/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  bool _cargando = false;
  String? _mensaje;
  bool _esError = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await ref.read(authRepositoryProvider).enviarCorreoRecuperacion(_correoCtrl.text.trim());
      setState(() {
        _mensaje = 'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.';
        _esError = false;
      });
    } catch (e) {
      setState(() {
        _mensaje = mapSupabaseError(e).message;
        _esError = true;
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
                  ),
                  if (_mensaje != null) ...[
                    const SizedBox(height: 12),
                    Text(_mensaje!,
                        style: TextStyle(color: _esError ? Theme.of(context).colorScheme.error : null)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _cargando ? null : _enviar,
                    child: _cargando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Enviar enlace de recuperación'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Volver a iniciar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}