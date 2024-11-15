import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";

import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_translate/flutter_translate.dart" as translations;

import "package:likertshift/util.dart";

class JsonForm extends StatefulWidget {
  final String name;
  final String? prefix;
  final String? suffix;
  final void Function(BuildContext context)? onSubmit;
  final Widget? nextForm;
  const JsonForm(
    this.name, {
    super.key,
    this.prefix,
    this.suffix,
    this.onSubmit,
    this.nextForm,
  });

  @override
  State<JsonForm> createState() => _JsonFormState();
}

class _JsonFormState extends State<JsonForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  static const encoder = JsonEncoder.withIndent("    ");

  @override
  Widget build(BuildContext context) {
    final assets = DefaultAssetBundle.of(context);

    return FutureBuilder(
      future: assets.loadString("assets/forms/${widget.name}.json"),
      builder: (context, asset) {
        if (!asset.hasData) {
          return Container();
        }

        final form = json.decode(asset.data!);
        final formId = form["id"] as String;
        final formTitle = translate(form["title"] as String);
        final formNote = (form["note"] as String?)?.transformed(translate);
        final formText = (form["text"] as String?)?.transformed(translate);

        final nextFormId = form["next_form"] as String?;
        final nextForm = nextFormId != null
            ? JsonForm(
                nextFormId,
                prefix: widget.prefix,
                suffix: widget.suffix,
                onSubmit: widget.onSubmit,
                nextForm: widget.nextForm,
              )
            : null;

        final formFields = [];
        for (final field in form["fields"] as List<dynamic>) {
          if (field is! Map<String, dynamic>) {
            continue;
          }

          final fieldId = field["id"] as String;
          final fieldLabel = (field["label"] as String?)?.transformed(translate);
          final fieldNote = (field["note"] as String?)?.transformed(translate);

          final String fieldType;
          final fieldTypeBlob = field["fieldType"];
          if (fieldTypeBlob is String) {
            fieldType = fieldTypeBlob;
          } else if (fieldTypeBlob is Map<String, dynamic>) {
            fieldType = fieldTypeBlob["type"] as String;
          } else {
            continue;
          }

          final dynamic formField;
          switch (fieldType) {
            case "Int":
              formField = IntField(id: fieldId, label: fieldLabel, note: fieldNote);
            case "Enum":
              formField = EnumField(
                id: fieldId,
                label: fieldLabel,
                note: fieldNote,
                values: (fieldTypeBlob["values"] as List)
                    .map((value) => translate(value as String))
                    .toList(),
              );
            case "CustomEnum":
              formField = CustomEnumField(
                id: fieldId,
                label: fieldLabel,
                note: fieldNote,
                values: (fieldTypeBlob["values"] as List)
                    .map((value) => translate(value as String))
                    .toList(),
                customValue: (fieldTypeBlob["customValue"] as String?)?.transformed(translate),
                customLabel: (fieldTypeBlob["customLabel"] as String?)?.transformed(translate),
              );
            case "LikertScale":
              formField = LikertScaleField(
                id: fieldId,
                label: fieldLabel,
                note: fieldNote,
                steps: fieldTypeBlob["steps"] as int?,
                subdivisions: fieldTypeBlob["subdivisions"] as int?,
                signed: fieldTypeBlob["signed"] as bool?,
                negativeDescription: translate(fieldTypeBlob["negativeAnswer"] as String),
                positiveDescription: translate(fieldTypeBlob["positiveAnswer"] as String),
              );
            default:
              continue;
          }
          formFields.add(formField);
        }

        final theme = Theme.of(context);

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(title: Text(formTitle), automaticallyImplyLeading: false),
            body: FormListView(
              formKey: _formKey,
              children: [
                if (formNote != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      formNote,
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                if (formText != null) Text(formText, style: theme.textTheme.titleMedium),
                ...formFields,
                const Padding(padding: EdgeInsets.symmetric(vertical: 2)),
                ElevatedButton(
                  child: Text(
                    translations
                        .translate(nextForm == null ? "common.submit" : "common.next")
                        .toUpperCase(),
                  ),
                  onPressed: () async {
                    final formState = _formKey.currentState;
                    if (formState == null || !formState.saveAndValidate()) {
                      return;
                    }

                    final prefix = widget.prefix == null ? "" : "${widget.prefix}_";
                    final suffix = widget.suffix == null ? "" : "_${widget.suffix}";
                    final directory = await getStorageDirectory();
                    final file = File("${directory.path}/$prefix$formId$suffix.json");

                    await file.writeAsString(encoder.convert(formState.value));

                    if (context.mounted) {
                      if (nextForm != null) {
                        await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => nextForm),
                        );
                      } else if (widget.nextForm != null) {
                        await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => widget.nextForm!),
                        );
                      } else {
                        if (widget.onSubmit != null) {
                          widget.onSubmit!(context);
                        }
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final translateRegex = RegExp(r"translate\('(.*)'\)");
  String translate(String string) {
    return string.replaceAllMapped(
      translateRegex,
      (match) => translations.translate(match.group(1)!),
    );
  }
}

class IntField extends StatelessWidget {
  final String id;
  final String? label;
  final String? note;

  const IntField({super.key, required this.id, this.label, this.note});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: id,
      decoration: InputDecoration(label: Text(label ?? ""), hintText: note),
      keyboardType: TextInputType.number,
    );
  }
}

class EnumField extends StatelessWidget {
  final String id;
  final String? label;
  final String? note;
  final List<String> values;
  final void Function(String?)? onChanged;

  const EnumField({
    super.key,
    required this.id,
    this.label,
    this.note,
    required this.values,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderDropdown(
      name: id,
      decoration: InputDecoration(label: Text(label ?? ""), hintText: note),
      items: values
          .map((entry) => DropdownMenuItem(value: entry.toLowerCase(), child: Text(entry)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class CustomEnumField extends StatefulWidget {
  final String id;
  final String? label;
  final String? note;
  final List<String> values;
  final String? customLabel;
  final String? customValue;

  const CustomEnumField({
    super.key,
    required this.id,
    this.label,
    this.note,
    required this.values,
    this.customLabel,
    this.customValue,
  });

  @override
  State<CustomEnumField> createState() => _CustomEnumFieldState();
}

class _CustomEnumFieldState extends State<CustomEnumField> {
  bool showCustomInput = false;

  @override
  Widget build(BuildContext context) {
    final customLabel = widget.customLabel ?? translations.translate("forms.custom");
    final customValue = widget.customValue ?? customLabel;
    return Column(
      children: [
        EnumField(
          id: widget.id,
          label: widget.label,
          note: widget.note,
          values: widget.values + [customValue],
          onChanged: (value) {
            setState(() {
              showCustomInput = value == customValue.toLowerCase();
            });
          },
        ),
        if (showCustomInput)
          FormBuilderTextField(
            name: "${widget.id}_custom",
            decoration: InputDecoration(label: Text(customLabel)),
          ),
      ],
    );
  }
}

class LikertScaleField extends StatelessWidget {
  final String id;
  final String? label;
  final String? note;
  final int? steps;
  final int? subdivisions;
  final bool? signed;
  final String negativeDescription;
  final String positiveDescription;

  const LikertScaleField({
    super.key,
    required this.id,
    this.label,
    this.note,
    this.steps,
    this.subdivisions,
    this.signed,
    required this.negativeDescription,
    required this.positiveDescription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = this.steps ?? 5;
    final signed = this.signed ?? false;

    final trackColor = theme.colorScheme.surfaceContainerHigh;
    final tickMarkColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Wrap(
      children: [
        if (label != null) Text(label!, style: theme.textTheme.titleMedium),
        SliderTheme(
          data: theme.sliderTheme.copyWith(
            activeTrackColor: trackColor,
            activeTickMarkColor: tickMarkColor,
            inactiveTrackColor: trackColor,
            inactiveTickMarkColor: tickMarkColor,
            trackHeight: steps <= 7 ? 20 : 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: FormBuilderSlider(
            name: id,
            decoration: InputDecoration(
              label: Text(
                note ?? "",
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w300),
              ),
            ),
            minValueWidget: (_) => Expanded(
              flex: 20,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(negativeDescription),
              ),
            ),
            maxValueWidget: (_) => Expanded(
              flex: 20,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(positiveDescription, textAlign: TextAlign.right),
              ),
            ),
            initialValue: signed ? 0 : (steps ~/ 2) + 1,
            min: signed ? -(steps - 1) / 2 : 1,
            divisions: (steps - 1) * (subdivisions ?? 1),
            max: signed ? (steps - 1) / 2 : steps.toDouble(),
          ),
        ),
      ],
    );
  }
}
