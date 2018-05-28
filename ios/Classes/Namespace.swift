import Foundation

enum Namespace: String {
    case main = "flutter_ble_lib"
    case scanDevices = "flutter_ble_lib/startDeviceScan"
    case stateChange = "flutter_ble_lib/stateChange"
    case deviceConnectionChange = "flutter_ble_lib/deviceConnectionChange"
    case monitorCharacteristicChange = "flutter_ble_lib/monitorCharacteristicChange"
    case restoreState = "flutter_ble_lib/restoreState"
}
