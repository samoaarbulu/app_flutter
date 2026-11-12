import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Componente reutilizable de entrada de código OTP / PIN (por defecto 6 dígitos).
///
/// Características:
/// - Avance automático de foco al escribir.
/// - Retroceso inteligente al presionar borrar (backspace).
/// - Resalte de borde oscuro (#262626) en la celda activa / enfocada.
/// - Callbacks `onChanged` y `onCompleted`.
class AppOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final List<String>? initialValues;

  const AppOtpInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.initialValues,
  });

  @override
  State<AppOtpInput> createState() => _AppOtpInputState();
}

class _AppOtpInputState extends State<AppOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (i) => TextEditingController(
        text: (widget.initialValues != null && i < widget.initialValues!.length)
            ? widget.initialValues![i]
            : '',
      ),
    );
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Si se pega más de 1 carácter o se escribe
      final digit = value.length > 1 ? value[value.length - 1] : value;
      _controllers[index].text = digit;

      // Avanzar al siguiente campo si existe
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final code = _currentCode;
    widget.onChanged?.call(code);

    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final hasValue = _controllers[index].text.isNotEmpty;

        return SizedBox(
          width: 2.875.rem, // ~46 px
          height: 4.125.rem, // ~66 px
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isFocused
                    ? AppColors.primaryAction
                    : (hasValue
                        ? const Color(0xFFD1D1D6)
                        : const Color(0xFFE5E5EA)),
                width: isFocused ? 2.0 : 1.0,
              ),
            ),
            child: Center(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  // Manejar backspace para volver al campo anterior si está vacío
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      _controllers[index].text.isEmpty &&
                      index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                },
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 1.5.rem, // 24 px
                  ),
                  cursorColor: AppColors.primaryAction,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) => _onDigitChanged(index, val),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
