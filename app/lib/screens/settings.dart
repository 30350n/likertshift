import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:archive/archive_io.dart";
import "package:flutter_translate/flutter_translate.dart";
import "package:record/record.dart";
import "package:restart_app/restart_app.dart";

import "package:likertshift/forms.dart";
import "package:likertshift/system_navigation_bar.dart";
import "package:likertshift/util.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adaptiveTheme = AdaptiveTheme.of(context);
    final localization = LocalizedApp.of(context).delegate;
    final theme = Theme.of(context);

    return Scaffold(
      appBar:
          AppBar(leading: const Icon(Icons.settings), title: Text(translate("settings.title"))),
      body: SeperatedListView(
        padding: EdgeInsets.zero,
        spacing: 8,
        children: [
          ListTile(
            title: Text(translate("settings.language")),
            leading: const Icon(Icons.language),
            trailing: DropdownMenu<String>(
              initialSelection: localization.currentLocale.languageCode,
              dropdownMenuEntries: localization.supportedLocales
                  .map(
                    (locale) => DropdownMenuEntry(
                      value: locale.languageCode,
                      label: translate("settings.languages.${locale.languageCode}"),
                    ),
                  )
                  .toList(),
              onSelected: (language) async {
                if (language != null) {
                  await changeLocale(context, language);
                }
              },
            ),
          ),
          ListTile(
            title: Text(translate("settings.color_scheme")),
            leading: const Icon(Icons.format_paint),
            trailing: DropdownMenu<AdaptiveThemeMode>(
              initialSelection: adaptiveTheme.mode,
              dropdownMenuEntries: AdaptiveThemeMode.values
                  .map(
                    (mode) => DropdownMenuEntry(
                      value: mode,
                      label: translate("settings.color_schemes.${mode.name}"),
                    ),
                  )
                  .toList(),
              onSelected: (theme) {
                if (theme != null) {
                  adaptiveTheme.setThemeMode(theme);
                  updateSystemNavigationBarTheme();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InterviewScreen()),
                );
              },
              child: Text(
                translate("settings.record_interview"),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              onPressed: () => exportDataAndReset(context),
              child: Text(
                translate("settings.export_data_and_reset"),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            title:
                Text(translate("settings.debug_forms"), style: theme.textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              child: Text(
                translate("forms.demographics.title"),
                style: theme.textTheme.titleMedium,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JsonForm("demographics", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              child: Text(translate("forms.bfi-10.title"), style: theme.textTheme.titleMedium),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JsonForm("bfi-10", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              child: Text(translate("forms.tlx.title"), style: theme.textTheme.titleMedium),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JsonForm("tlx", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              child: Text("UEQ+", style: theme.textTheme.titleMedium),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const JsonForm("ueq_01_attractiveness", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> exportDataAndReset(BuildContext context) async {
    final resultsDirectory = await getResultsDirectory();
    final dataDirectory = await getStorageDirectory();

    final participantId = shortHash(DateTime.now());
    final name = "participant-data-$participantId";
    final archive = ZipFileEncoder()..create("${resultsDirectory.path}/$name.zip");
    await dataDirectory.list().forEach(
      (entry) async {
        switch (entry.statSync().type) {
          case FileSystemEntityType.directory:
            if (entry.path == resultsDirectory.path) {
              return;
            }
            return archive
                .addDirectory(Directory(entry.path), followLinks: false)
                .then((_) => entry.delete(recursive: true));
          case FileSystemEntityType.file:
            return archive.addFile(File(entry.path)).then((_) => entry.delete());
          default:
        }
      },
    );
    archive.closeSync();

    if (context.mounted) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ResetScreen(participantId)));
    }
  }
}

class ResetScreen extends StatelessWidget {
  final String participantId;

  const ResetScreen(this.participantId, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            children: [
              const Icon(Icons.celebration, size: 200),
              Text(
                translate("settings.reset_screen.thanks_for_participating"),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                "${translate("settings.reset_screen.participant_id")} $participantId",
                style: theme.textTheme.titleSmall,
              ),
              if (Platform.isAndroid)
                ElevatedButton(
                  onPressed: Restart.restartApp,
                  child: Text(translate("settings.reset_screen.reset_app").toUpperCase()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  late StreamSubscription<RecordState> recordStateSubscription;
  RecordState recordState = RecordState.stop;

  final audioRecorder = AudioRecorder();

  Timer? timer;
  DateTime? startTime;
  Duration recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    recordStateSubscription = audioRecorder.onStateChanged().listen((state) {
      setState(() {
        recordState = state;
      });
    });
  }

  @override
  void dispose() {
    recordStateSubscription.cancel();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconButtonStyle = ButtonStyle(
      shape: const WidgetStatePropertyAll(CircleBorder()),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(18)),
      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHigh),
      foregroundColor: WidgetStatePropertyAll(theme.colorScheme.onSurfaceVariant),
      iconColor: WidgetStatePropertyAll(theme.colorScheme.onSurfaceVariant),
      iconSize: const WidgetStatePropertyAll(28),
    );

    final totalRecordingDuration = startTime != null
        ? recordingDuration + DateTime.now().difference(startTime!)
        : recordingDuration;

    return PopScope(
      canPop: recordState == RecordState.stop,
      child: Scaffold(
        appBar: AppBar(title: const Text("Interview")),
        body: Center(
          child: Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (recordState == RecordState.stop)
                ElevatedButton(
                  style: iconButtonStyle,
                  child: const Icon(Icons.mic),
                  onPressed: () async {
                    if (!await audioRecorder.hasPermission()) {
                      return;
                    }

                    const recordConfig = RecordConfig(
                      encoder: AudioEncoder.flac,
                      autoGain: true,
                      numChannels: 1,
                    );
                    await audioRecorder.start(
                      recordConfig,
                      path: uniquePath("${(await getStorageDirectory()).path}/interview.flac"),
                    );

                    startTime = DateTime.now();
                    recordingDuration = Duration.zero;
                    timer = Timer.periodic(const Duration(seconds: 1), (_) {
                      setState(() {});
                    });
                  },
                )
              else ...[
                ElevatedButton(
                  style: iconButtonStyle.copyWith(
                    backgroundColor: const WidgetStatePropertyAll(Colors.red),
                    iconColor: WidgetStatePropertyAll(Colors.grey.shade200),
                  ),
                  onPressed: () {
                    timer?.cancel();
                    audioRecorder.stop();
                  },
                  child: const Icon(Icons.stop),
                ),
                if (recordState == RecordState.pause)
                  ElevatedButton(
                    style: iconButtonStyle,
                    onPressed: () {
                      audioRecorder.resume();
                      startTime = DateTime.now();
                    },
                    child: const Icon(Icons.play_arrow),
                  )
                else
                  ElevatedButton(
                    style: iconButtonStyle,
                    onPressed: () {
                      audioRecorder.pause();
                      recordingDuration += DateTime.now().difference(startTime!);
                      startTime = null;
                    },
                    child: const Icon(Icons.pause),
                  ),
                SizedBox(
                  width: totalRecordingDuration.inHours > 0 ? 80 : 64,
                  child: Text(
                    totalRecordingDuration.pretty(),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
