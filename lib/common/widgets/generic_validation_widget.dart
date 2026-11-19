import "package:flutter/material.dart";

import "custom_decoration.dart";

///Note: This code is written by Kapil dai, on any error contact him not me. Hope it works.
class GenericValidationWidget<T> extends StatefulWidget {
  final String? Function(T?) validator;
  final Widget child;
  final void Function(T?)? onChanged;
  final ValueNotifier<T> controller;
  final GlobalKey<FormFieldState>? textFieldKey;

  const GenericValidationWidget({
    super.key,
    required this.validator,
    this.textFieldKey,
    this.onChanged,
    required this.child,
    required this.controller,
  });

  @override
  GenericValidationWidgetState<T> createState() =>
      GenericValidationWidgetState<T>();
}

class GenericValidationWidgetState<T>
    extends State<GenericValidationWidget<T>> {
  FormFieldState<T>? _formFieldState;

  @override
  void initState() {
    super.initState();
    // Listen to text changes
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Notify the parent widget of the change
    widget.onChanged?.call(widget.controller.value);
    // Notify the form field of the new value
    // _formFieldState.didChange(widget.controller.text as T?);
    _formFieldState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: widget.textFieldKey,
      initialValue: widget.controller.value,
      validator: (value) {
        // Validate using the provided validator function
        return widget.validator(widget.controller.value);
      },
      builder: (FormFieldState<T> formFieldState) {
        _formFieldState = formFieldState; // Store the FormFieldState
        final error=formFieldState.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use the provided child widget
            SizedBox(
              key: ValueKey(error),
              child: widget.child,
            ),
            // Show error message if validation fails
            if (error)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  formFieldState.errorText!,
                  style: CustomDecoration.errorStyle,
                ),
              ),
          ],
        );
      },
    );
  }
}
