//
//  FlutterBleLibPlugin+Helpers.swift
//  flutter_ble_lib
//
//  Created by Paweł Janeczek on 28/05/2018.
//

import Foundation

extension SwiftFlutterBleLibPlugin {
    func ensureManagerCreated() throws -> BleClientManager {
        guard let manager = manager else {
            throw LibError.flutterError(FlutterError.clientNotCreated())
        }
        return manager
    }

    func retrieveDeviceId(fromArgument arguments: Any?, function: String = #function) throws -> String {
        guard let deviceId = arguments as? String else {
            throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        return deviceId
    }

    func retrieveScanDataMessage(fromArguments arguments: Any?, function: String = #function) throws -> ScanDataMessage {
        guard let typedData = arguments as? FlutterStandardTypedData else {
            throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: function, arguments: arguments))
        }
        do {
            let message = try ScanDataMessage(serializedData: typedData.data)
            return message
        } catch {
            throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: function, arguments: arguments))
        }
    }

    func retrieveDeviceMessage(fromArguments arguments: Any?, function: String = #function) throws -> BleDeviceMessage {
        guard let typedData = arguments as? FlutterStandardTypedData else {
            throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: function, arguments: arguments))
        }
        do {
            let message = try BleDeviceMessage(serializedData: typedData.data)
            return message
        } catch {
            throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: function, arguments: arguments))
        }
    }

    func handleDeviceMessageResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let dict = obj as? [String: AnyObject], let message = BleDeviceMessage(bleData: dict) else {
                result(FlutterError.dataSerializationFailed(data: obj, details: function))
                return
            }
            do {
                result(FlutterStandardTypedData(bytes: try message.serializedData()))
            } catch {
                result(FlutterError.dataSerializationFailed(data: message, details: function))
            }
        }
    }

    func handleServicesMessageResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let dict = obj as? [String: AnyObject], let message = ServiceMessage(bleData: dict) else {
                result(FlutterError.dataSerializationFailed(data: obj, details: function))
                return
            }
            do {
                result(FlutterStandardTypedData(bytes: try message.serializedData()))
            } catch {
                result(FlutterError.dataSerializationFailed(data: message, details: function))
            }
        }
    }

    func handleCharacteristicMessagesResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let arr = obj as? [[String: AnyObject]], let message = CharacteristicMessages(bleData: arr) else {
                result(FlutterError.dataSerializationFailed(data: obj, details: function))
                return
            }
            do {
                result(FlutterStandardTypedData(bytes: try message.serializedData()))
            } catch {
                result(FlutterError.dataSerializationFailed(data: message, details: function))
            }
        }
    }

    func handleCharacteristicMessageResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let dict = obj as? [String: AnyObject], let message = CharacteristicMessage(bleData: dict) else {
                result(FlutterError.dataSerializationFailed(data: obj, details: function))
                return
            }
            do {
                result(FlutterStandardTypedData(bytes: try message.serializedData()))
            } catch {
                result(FlutterError.dataSerializationFailed(data: message, details: function))
            }
        }
    }

    func handleReject(result: @escaping FlutterResult, function: String = #function) -> Reject {
        return { (code, message, error) in
            result(FlutterError(code: code ?? "Unknown", message: message, details: "requestMTUForDevice"))
        }
    }
}
