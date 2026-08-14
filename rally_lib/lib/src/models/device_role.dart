/// The operational role of this installation in a rally BLE group.
enum DeviceRole { controller, driver, navigator }

extension DeviceRoleStorage on DeviceRole {
  String get storageValue => name;

  static DeviceRole fromStorage(String? value) => DeviceRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => DeviceRole.controller,
  );
}
