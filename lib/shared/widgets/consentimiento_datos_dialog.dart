import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

const _urlPoliticaDatos =
    'https://drive.google.com/file/d/1RLycscfrCwhHdk8q5PiUInDoL3xOvt_G/view?usp=sharing';

/// Muestra el modal de autorización de tratamiento de datos personales.
/// Devuelve `true` solo si el usuario marcó la casilla y tocó "Continuar".
Future<bool> mostrarConsentimientoDatos(BuildContext context) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _ConsentimientoDatosDialog(),
  );
  return resultado ?? false;
}

class _ConsentimientoDatosDialog extends StatefulWidget {
  const _ConsentimientoDatosDialog();

  @override
  State<_ConsentimientoDatosDialog> createState() => _ConsentimientoDatosDialogState();
}

class _ConsentimientoDatosDialogState extends State<_ConsentimientoDatosDialog> {
  bool _aceptado = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Tratamiento de datos personales'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para usar Participa necesitamos tu autorización para el tratamiento de tus '
                'datos personales (nombre, correo, teléfono y la información que registres), '
                'conforme a la Ley 1581 de 2012 de Colombia.',
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => launchUrl(Uri.parse(_urlPoliticaDatos), mode: LaunchMode.externalApplication),
                child: const Text(
                  'Ver la Política de Tratamiento de Datos Personales',
                  style: TextStyle(color: AppColors.violeta, decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _aceptado,
                onChanged: (v) => setState(() => _aceptado = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Acepto los términos y la Política de Tratamiento de Datos Personales',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No acepto')),
          FilledButton(
            onPressed: _aceptado ? () => Navigator.of(context).pop(true) : null,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}