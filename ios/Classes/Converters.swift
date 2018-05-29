import Foundation
import Flutter

struct EventData<T> {
    let error: FlutterError?
    let data: T?
    let additionalData: Any?

    init?(value: Any) {
        if let arrValue = value as? Array<Any> {
            if let errorData = arrValue[0] as? [String: String], let code = errorData["code"] {
                self.error = FlutterError(code: code, message: errorData["message"], details: nil)
            } else {
                self.error = nil
            }
            self.data = arrValue[1] as? T
            self.additionalData = arrValue.count > 2 ? arrValue[2] : nil
        } else if let data = value as? T {
            self.data = data
            self.error = nil
            self.additionalData = nil
        } else {
            return nil
        }
    }
}

extension BluetoothStateMessage {
    init?(string: String) {
        switch string {
        case "Unknown":
            self = .unknown
        case "Resetting":
            self = .resetting
        case "Unsupported":
            self = .unsupported
        case "Unauthorized":
            self = .unauthorized
        case "PoweredOff":
            self = .poweredOff
        case "PoweredOn":
            self = .poweredOn
        default:
            return nil
        }
    }
}

extension ScanResultMessage {
    init?(bleData: [String: AnyObject]) {
        guard let rssi = bleData["rssi"] as? Int32,
            let deviceId = bleData["id"] as? String,
            let mtu = bleData["mtu"] as? Int32 else {
                return nil
        }
        self.rssi = rssi
        bleDeviceMessage = BleDeviceMessage()
        bleDeviceMessage.id = deviceId
        bleDeviceMessage.name = (bleData["name"] as? String) ?? ""
        bleDeviceMessage.rssi = rssi
        bleDeviceMessage.mtu = mtu
    }
}

extension BleDeviceMessage {
    init?(bleData: [String: AnyObject]) {
        guard let id = bleData["id"] as? String, let mtu = bleData["mtu"] as? Int32 else {
            return nil
        }
        self.id = id
        self.name = (bleData["name"] as? String) ?? ""
        self.rssi = (bleData["rssi"] as? Int32) ?? 0
        self.mtu = mtu
    }
}

extension ServiceMessages {
    init?(bleData: [[String: AnyObject]]) {
        var services: [ServiceMessage] = []
        for data in bleData {
            guard let service = ServiceMessage(bleData: data) else {
                return nil
            }
            services.append(service)
        }
        serviceMessages = services
    }
}

extension ServiceMessage {
    init?(bleData: [String: AnyObject]) {
        guard
            let id = bleData["id"] as? Double,
            let deviceId = bleData["deviceID"] as? String,
            let uuid = bleData["uuid"] as? String,
            let isPrimary = bleData["isPrimary"] as? Bool else {
            return nil
        }
        self.id = id
        device = BleDeviceMessage()
        device.id = deviceId
        self.uuid = uuid
        self.isPrimary = isPrimary
    }
}

extension CharacteristicMessages {
    init?(bleData: [[String: AnyObject]]) {
        var characteristics: [CharacteristicMessage] = []
        for data in bleData {
            guard let characteristic = CharacteristicMessage(bleData: data) else {
                return nil
            }
            characteristics.append(characteristic)
        }
        characteristicMessage = characteristics
    }
}

extension CharacteristicMessage {
    init?(bleData: [String: AnyObject]) {
        guard let id = bleData["id"] as? Double,
            let uuid = bleData["uuid"] as? String,
            let deviceId = bleData["deviceID"] as? String,
            let serviceUuid = bleData["serviceUUID"] as? String,
            let serviceId = bleData["serviceID"] as? Int64,
            let isIndicatableInt = bleData["isIndicatable"] as? Int,
            let isNotifiableInt = bleData["isNotifiable"] as? Int,
            let isNotifyingInt = bleData["isNotifying"] as? Int,
            let isReadableInt = bleData["isReadable"] as? Int,
            let isWritableWithResponseInt = bleData["isWritableWithResponse"] as? Int,
            let isWritableWithoutResponseInt = bleData["isWritableWithoutResponse"] as? Int else {
                return nil
        }
        self.id = id
        self.uuid = uuid
        self.deviceID = deviceId
        self.serviceUuid = serviceUuid
        self.serviceID = serviceId
        self.isIndicatable = isIndicatableInt == 1
        self.isNotificable = isNotifiableInt == 1
        self.isNotifing = isNotifyingInt == 1
        self.isReadable = isReadableInt == 1
        self.isWritableWithResponse = isWritableWithResponseInt == 1
        self.isWritableWithoutResponse = isWritableWithoutResponseInt == 1
        self.value = (bleData["value"] as? String) ?? ""
    }
}

extension MonitorCharacteristicMessage {
    init?(bleData: [String: AnyObject], transactionID: Any?) {
        guard let characteristic = CharacteristicMessage(bleData: bleData), let transactionID = transactionID as? String else {
            return nil
        }
        self.transactionID = transactionID
        self.characteristicMessage = characteristic
    }
}
