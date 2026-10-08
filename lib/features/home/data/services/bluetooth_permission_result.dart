/// Coarse-grained result of requesting the runtime permissions required to
/// scan for and connect to BLE heart-rate monitors.
///
/// `granted`            — every required permission was returned granted.
/// `denied`             — the user denied at least one permission; can re-ask.
/// `permanentlyDenied`  — at least one permission is set to "don't ask
///                        again"; the UI should offer an Open-Settings link.
/// `unsupported`          — the device hardware does not support BLE at all.
enum BluetoothPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}