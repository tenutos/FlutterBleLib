import Foundation

struct EventData<T> {
    let error: FlutterError?
    let data: T?

    init?(value: Any) {
        if let arrValue = value as? Array<Any> {
            if let errorData = arrValue[0] as? [String: String], let code = errorData["code"] {
                self.error = FlutterError(code: code, message: errorData["message"], details: nil)
            } else {
                self.error = nil
            }
            self.data = arrValue[1] as? T
        } else if let data = value as? T {
            self.data = data
            self.error = nil
        } else {
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
        guard let id = bleData["id"] as? String, let rssi = bleData["rssi"] as? Int32, let mtu = bleData["mtu"] as? Int32 else {
            return nil
        }
        self.id = id
        self.name = (bleData["name"] as? String) ?? ""
        self.rssi = rssi
        self.mtu = mtu
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
            let serviceId = bleData["serviceID"] as? Int32,
            let isIndicatableString = bleData["isIndicatable"] as? String,
            let isNotificableString = bleData["isNotificable"] as? String,
            let isNotifingString = bleData["isNotifing"] as? String,
            let isReadableString = bleData["isReadable"] as? String,
            let isWritableWithResponseString = bleData["isWritableWithResponse"] as? String,
            let isWritableWithoutResponseString = bleData["isWritableWithoutResponse"] as? String else {
                return nil
        }
        self.id = id
        self.uuid = uuid
        self.deviceID = deviceId
        self.serviceUuid = serviceUuid
        self.serviceID = serviceId
        self.isIndicatable = isIndicatableString == "1"
        self.isNotificable = isNotificableString == "1"
        self.isNotifing = isNotifingString == "1"
        self.isReadable = isReadableString == "1"
        self.isWritableWithResponse = isWritableWithResponseString == "1"
        self.isWritableWithoutResponse = isWritableWithoutResponseString == "1"

    }
}
