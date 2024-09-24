[![flutter](https://img.shields.io/badge/Flutter-3.24-aqua)](https://flutter.dev)
[![license](https://img.shields.io/badge/License-MIT-lightgray)](app/LICENSE)

# Likertshift

The Likertshift project introduces a novel way of collecting Travel Satisfaction data while Cycling, by using a gearshift-like Device that reports to the users smartphone via BLE.

## Repository Overview

### [App](app/)

The Likertshift App provides different methods for recording Travel Satisfaction while Cycling (or any other data, that can be represented on a Likert Scale).

#### Supported Recording Methods

- Likertshift Device
- Synchronized Audio Recording
- Retrospective Manual Mapping

It supports storing pre-defined routes, but can all also be used for free-roaming.

It is designed to be easily customizable, so you can adjust it to your needs to conduct you own Field Studies.

#### Data-Privacy

The App stores all the recorded data locally.

The `Export Data & Reset` option in the `Settings` tab can be used to export all the recorded data to a `.zip` archive and subsequently delete it from the local App storage.

*Note: Usage of the [MapTiler API](app/lib/api-keys/README.md#maptilerdart) allows [MapTiler AG](https://www.maptiler.com/) to indirectly track the [users location and IP address](https://www.maptiler.com/privacy-policy/).*

## Licenses

- The code included in this project is licensed under the [MIT](app/LICENSE) license.
