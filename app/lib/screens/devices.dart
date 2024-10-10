import "dart:io";

import "package:flutter/material.dart";

import "package:flutter_blue_plus/flutter_blue_plus.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:provider/provider.dart";

import "package:likertshift/colors.dart";
import "package:likertshift/bluetooth.dart";
import "package:likertshift/location.dart";

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothModel = context.watch<BluetoothModel>();
    final isLocationEnabled = context.select<LocationModel, bool?>((m) => m.isLocationEnabled);

    return Scaffold(
      appBar:
          AppBar(leading: const Icon(Icons.devices), title: const Text("Likertshift Devices")),
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
                          (device) => DeviceCard(device.remoteId.str, device.isConnected),
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

class DeviceCard extends StatelessWidget {
  final String name;
  final bool isConnected;

  const DeviceCard(this.name, this.isConnected, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: isConnected
            ? Icon(Icons.bluetooth, color: appColors?.connectedColor)
            : const Icon(Icons.bluetooth_disabled),
        title: Text(name),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              )
            : Icon(Icons.settings, color: theme.disabledColor),
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

  const BluetoothOffScreen(this.adapterState, {super.key});

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
          Text("Bluetooth Adapter is ${adapterState.name}", style: theme.textTheme.titleMedium),
          if (Platform.isAndroid)
            const ElevatedButton(onPressed: FlutterBluePlus.turnOn, child: Text("TURN ON")),
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
          Text("Location Service is disabled", style: theme.textTheme.titleMedium),
          const ElevatedButton(
            onPressed: LocationModel.requestLocationService,
            child: Text("TURN ON"),
          ),
        ],
      ),
    );
  }
}
