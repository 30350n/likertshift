import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:provider/provider.dart";

import "package:likertshift/util.dart";

enum Gender {
  male,
  female,
  other;

  static Gender? fromString(String string) =>
      Gender.values.firstWhere((gender) => gender.name == string);
}

enum BikeUsageFrequency {
  daily(description: "Multiple Times per Day"),
  weekly(description: "Multiple Times per Week"),
  monthly(description: "Multiple Times per Month"),
  yearly(description: "Multiple Times per Year");

  final String description;
  const BikeUsageFrequency({required this.description});

  static BikeUsageFrequency fromString(String string) =>
      BikeUsageFrequency.values.firstWhere((usageFrequency) => usageFrequency.name == string);
}

enum BikeShiftType {
  twist(description: "Twist Shift"),
  lever(description: "Lever Shift"),
  brake(description: "Brake Shift"),
  other(description: "Other"),
  none(description: "None");

  final String description;
  const BikeShiftType({required this.description});

  static BikeShiftType fromString(String string) =>
      BikeShiftType.values.firstWhere((bikeShiftType) => bikeShiftType.name == string);
}

class DemographicsModel with ChangeNotifier {
  String _id = shortHash(DateTime.now());

  int? _age;
  int? get age => _age;

  Gender? _gender;
  Gender? get gender => _gender;

  String? _genderCustom;
  String? get genderCustom => _genderCustom;

  BikeUsageFrequency? _bikeUsageFrequency;
  BikeUsageFrequency? get bikeUsageFrequency => _bikeUsageFrequency;

  BikeShiftType? _bikeShiftType;
  BikeShiftType? get bikeShiftType => _bikeShiftType;

  static Future<DemographicsModel> create() async {
    final model = DemographicsModel();
    await model.load();
    return model;
  }

  void setFromForm(FormBuilderState state) {
    _age = int.tryParse(state.fields["age"]?.value);
    _gender = state.fields["gender"]?.value;
    _genderCustom = state.fields["genderCustom"]?.value;
    _bikeUsageFrequency = state.fields["bikeUsageFrequency"]?.value;
    _bikeShiftType = state.fields["bikeShiftType"]?.value;
    save();
    notifyListeners();
  }

  bool isValid() {
    return [age, gender, bikeShiftType].every((value) => value != null);
  }

  Future<File> get _file async {
    final directory = await getStorageDirectory();
    return File("${directory.path}/demographics.json");
  }

  Future<File> save() async {
    final file = await _file;
    return file.writeAsString(
      jsonEncode({
        "id": _id,
        "age": age,
        "gender": gender == Gender.other ? genderCustom?.toLowerCase() : gender?.name,
        "bike_usage_frequency": bikeUsageFrequency?.name,
        "bike_shift_type": bikeShiftType?.name,
      }),
    );
  }

  Future<void> load() async {
    final file = await _file;

    if (!await file.exists()) {
      return;
    }

    final data = jsonDecode(await file.readAsString()) as Map;

    _id = data["id"] ?? _id;
    _age = data["age"] ?? _age;
    final gender = data["gender"];
    if (gender != null) {
      if (Gender.values.map((v) => v.name).contains(gender) && gender != "other") {
        _gender = Gender.fromString(gender);
        _genderCustom = null;
      } else {
        _gender = Gender.other;
        _genderCustom = gender;
      }
    }
    _bikeUsageFrequency = BikeUsageFrequency.fromString(data["bike_usage_frequency"]);
    _bikeShiftType = BikeShiftType.fromString(data["bike_shift_type"]);

    notifyListeners();
  }
}

class Demographics extends StatefulWidget {
  const Demographics({super.key});

  @override
  State<Demographics> createState() => _DemographicsState();
}

class _DemographicsState extends State<Demographics> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool showGenderInput = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Participant Information"),
        actions: [
          IconButton(
            onPressed: () {
              final currentState = _formKey.currentState;
              if (currentState?.validate() ?? false) {
                final model = context.read<DemographicsModel>();
                model.setFromForm(currentState!);
              }
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: FormListView(
        formKey: _formKey,
        children: [
          FormBuilderTextField(
            name: "age",
            decoration: const InputDecoration(label: Text("Age")),
            validator: FormBuilderValidators.numeric(),
            keyboardType: TextInputType.number,
          ),
          FormBuilderDropdown(
            name: "gender",
            decoration: const InputDecoration(label: Text("Self-Identified Gender")),
            validator: FormBuilderValidators.required(),
            items: Gender.values
                .map(
                  (gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender.name.capitalize()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                showGenderInput = value == Gender.other;
              });
            },
          ),
          if (showGenderInput)
            FormBuilderTextField(
              name: "genderCustom",
              decoration: const InputDecoration(label: Text("Other Gender")),
            ),
          FormBuilderDropdown(
            name: "bikeUsageFrequency",
            decoration: const InputDecoration(label: Text("Typical Bike Usage Frequency")),
            validator: FormBuilderValidators.required(),
            items: BikeUsageFrequency.values
                .map(
                  (usage) => DropdownMenuItem(
                    value: usage,
                    child: Text(usage.description),
                  ),
                )
                .toList(),
          ),
          FormBuilderDropdown(
            name: "bikeShiftType",
            decoration: const InputDecoration(label: Text("Most used Gear Shift Type")),
            validator: FormBuilderValidators.required(),
            items: BikeShiftType.values
                .map(
                  (shiftType) => DropdownMenuItem(
                    value: shiftType,
                    child: Text(shiftType.description),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
