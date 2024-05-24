import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String hintText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final bool? obscureText;
  final Widget? suffixIcon;
  final TextStyle? hintStyle;
  final int? maxLines;
  final int? minLines;
  final bool? readOnly;
  final InputBorder? border;
  final Function(String)? onChanged;
  final Color? fillColor;
  final Color? prefixIconColor;
  final InputBorder? enabledBorder;

  const InputField({
    required this.hintText,
    required this.keyboardType,
    required this.controller,
    this.validator,
    this.prefixIcon,
    this.obscureText,
    this.suffixIcon,
    this.hintStyle,
    this.maxLines,
    this.minLines,
    this.onChanged,
    this.readOnly,
    this.border,
    this.fillColor,
    this.prefixIconColor,
    this.enabledBorder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly ?? false,
      keyboardType: keyboardType,
      controller: controller,
      obscureText: obscureText ?? false,
      minLines: minLines,
      maxLines: obscureText == null
          ? maxLines
          : obscureText == true
              ? 1
              : maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.all(8.0),
        enabledBorder: enabledBorder,
        border: border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
        prefixIconColor: Colors.black,
        fillColor: fillColor,
        filled: true,
        hintStyle: hintStyle,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
