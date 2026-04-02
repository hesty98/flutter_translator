import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class EditableTranslationField extends HookWidget {
  const EditableTranslationField({
    required this.value,
    required this.label,
    required this.onSave,
    super.key,
    this.autofocus = false,
  });

  final String value;
  final String label;
  final ValueChanged<String> onSave;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);
    final focusNode = useFocusNode();

    useEffect(() {
      if (!focusNode.hasFocus && controller.text != value) {
        controller.text = value;
      }
      return null;
    }, [value, focusNode.hasFocus]);

    useEffect(() {
      void listener() {
        if (focusNode.hasFocus) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
      }

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode, controller]);

    void saveIfNeeded() {
      if (controller.text != value) {
        onSave(controller.text);
      }
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      minLines: 1,
      maxLines: null,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => saveIfNeeded(),
      onTapOutside: (_) => saveIfNeeded(),
      decoration: InputDecoration(labelText: label),
    );
  }
}
