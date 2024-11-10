import "dart:async";
import "dart:io";

import "package:flutter/material.dart";

import "package:flutter_blue_plus/flutter_blue_plus.dart";
import "package:flutter_translate/flutter_translate.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:provider/provider.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/location.dart";
import "package:likertshift/snackbar.dart";

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothModel = context.watch<BluetoothModel>();
    final isLocationEnabled = context.select<LocationModel, bool?>((m) => m.isLocationEnabled);

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.devices),
        title: Text(translate("devices.title")),
      ),
      body: switch (bluetoothModel.adapterState) {
        BluetoothAdapterState.unknown || BluetoothAdapterState.turningOff => Container(),
        BluetoothAdapterState.on || BluetoothAdapterState.turningOn => isLocationEnabled == null
            ? Container()
            : isLocationEnabled
                ? RefreshIndicator(
                    onRefresh: bluetoothModel.startScan,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        ...bluetoothModel.devices.map(
                          (device) => DeviceCard(bluetoothModel, device),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Center(child: ScanningIndicator(bluetoothModel.isScanning)),
                        ),
                      ],
                    ),
                  )
                : const LocationOffScreen(),
        _ => BluetoothOffScreen(bluetoothModel.adapterState),
      },
    );
  }
}

class DeviceCard extends StatefulWidget {
  final BluetoothModel bluetoothModel;
  final BluetoothDevice device;

  const DeviceCard(this.bluetoothModel, this.device, {super.key});

  @override
  State<StatefulWidget> createState() {
    return DeviceCardState();
  }
}

class DeviceCardState extends State<DeviceCard> {
  late StreamSubscription<BluetoothConnectionState> connectionSubscription;

  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    connectionSubscription = widget.device.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.connected) {
        widget.device.discoverServices();
        widget.bluetoothModel.activeDevice = widget.device;
      } else if (connectionState == BluetoothConnectionState.disconnected) {
        widget.bluetoothModel.activeDevice = null;
      }
    });
  }

  @override
  void dispose() {
    connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bluetoothStatus = isAvailable
        ? widget.device.isConnected
            ? BluetoothStatus.connected
            : BluetoothStatus.available
        : BluetoothStatus.unavailable;

    final name = widget.device.platformName != ""
        ? widget.device.platformName
        : widget.device.advName != ""
            ? widget.device.advName
            : widget.device.remoteId.str;

    return Card(
      color: switch (bluetoothStatus) {
        BluetoothStatus.connected => theme.colorScheme.surfaceContainerHigh,
        BluetoothStatus.available => theme.colorScheme.surfaceContainer,
        BluetoothStatus.unavailable => theme.colorScheme.surfaceContainerLow,
      },
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 6),
        leading: BluetoothLogo(bluetoothStatus: bluetoothStatus),
        title: Text(name),
        trailing: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: widget.device.isConnected ? () {} : null,
        ),
        onTap: () async {
          if (!widget.device.isConnected) {
            try {
              await widget.device.connect();
            } on Exception {
              if (context.mounted) {
                showSnackbarMessage(
                  context,
                  translate("devices.connection_error"),
                  success: false,
                );
              }
              setState(() {
                isAvailable = false;
              });
            }
          } else {
            try {
              await widget.device.disconnect();
            } catch (_) {}
          }
        },
      ),
    );
  }
}

class ScanningIndicator extends StatelessWidget {
  final bool isScanning;

  const ScanningIndicator(this.isScanning, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      opacity: isScanning ? 1 : 0,
      duration: Durations.short4,
      child: LoadingAnimationWidget.staggeredDotsWave(color: theme.primaryColorLight, size: 40),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  BluetoothOffScreen(this.adapterState, {super.key});

  final adaptlerStateMap = {
    BluetoothAdapterState.off: translate("common.off"),
    BluetoothAdapterState.on: translate("common.on"),
    BluetoothAdapterState.turningOff: translate("common.on"),
    BluetoothAdapterState.turningOn: translate("common.off"),
    BluetoothAdapterState.unauthorized: translate("devices.bluetooth_state.unauthorized"),
    BluetoothAdapterState.unavailable: translate("devices.bluetooth_state.unavailable"),
    BluetoothAdapterState.unknown: translate("devices.bluetooth_state.unknown"),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 15,
        children: [
          const Icon(
            Icons.bluetooth_disabled,
            size: 200,
          ),
          Text(
            "${translate("devices.blueetooth_adapter_is")} ${adaptlerStateMap[adapterState]}",
            style: theme.textTheme.titleMedium,
          ),
          if (Platform.isAndroid)
            ElevatedButton(
              onPressed: FlutterBluePlus.turnOn,
              child: Text(translate("common.turn_on").toUpperCase()),
            ),
        ],
      ),
    );
  }
}

class LocationOffScreen extends StatelessWidget {
  const LocationOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 15,
        children: [
          const Icon(
            Icons.location_off,
            size: 200,
          ),
          Text(translate("common.location_disabled"), style: theme.textTheme.titleMedium),
          ElevatedButton(
            onPressed: LocationModel.requestLocationService,
            child: Text(translate("common.turn_on").toUpperCase()),
          ),
        ],
      ),
    );
  }
}
