import Foundation
import Flutter

extension SwiftFlutterBleLibPlugin {
    func ensureManagerCreated() throws -> BleClientManager {
        guard let manager = manager else {
            throw LibError.flutterError(FlutterError.clientNotCreated())
        }
        return manager
    }

    func retrieveDeviceId(fromArgument arguments: Any?, function: String = #function) throws -> String {
        guard let deviceId = arguments as? String else {
            fatalError(LibError.createIncorrectArgumentsMessage(arguments: arguments))
        }
        return deviceId
    }

    func retrieveScanDataMessage(fromArguments arguments: Any?, function: String = #function) throws -> ScanDataMessage {
        guard let typedData = arguments as? FlutterStandardTypedData else {
            fatalError(LibError.createIncorrectArgumentsMessage(arguments: arguments))
        }
        do {
            let message = try ScanDataMessage(serializedData: typedData.data)
            return message
        } catch {
            fatalError(LibError.createDataSerializationFailedMessage(data: arguments))
        }
    }

    func retrieveDeviceMessage(fromArguments arguments: Any?, function: String = #function) throws -> BleDeviceMessage {
        guard let typedData = arguments as? FlutterStandardTypedData else {
            fatalError(LibError.createIncorrectArgumentsMessage(arguments: arguments))
        }
        do {
            let message = try BleDeviceMessage(serializedData: typedData.data)
            return message
        } catch {
            fatalError(LibError.createDataSerializationFailedMessage(data: arguments))
        }
    }

    func handleDeviceMessageResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let dict = obj as? [String: AnyObject], let message = BleDeviceMessage(bleData: dict) else {
                fatalError(LibError.createDataSerializationFailedMessage(data: obj))
            }
            do {
                result(FlutterStandardTypedData(bytes: try message.serializedData()))
            } catch {
                fatalError(LibError.createDataSerializationFailedMessage(data: message))
            }
        }
    }

    func handleServicesMessageResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let services = obj as? [[String: AnyObject]], let messages = ServiceMessages(bleData: services) else {
                fatalError(LibError.createDataSerializationFailedMessage(data: obj))
            }
            do {
                result(FlutterStandardTypedData(bytes: try messages.serializedData()))
            } catch {
                fatalError(LibError.createDataSerializationFailedMessage(data: messages))
            }
        }
    }

    func handleCharacteristicMessagesResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let arr = obj as? [[String: AnyObject]], let message = CharacteristicMessages(bleData: arr) else {
                fatalError(LibError.createDataSerializationFailedMessage(data: obj))
            }
            do {
                result(FlutterStandardTypedData(bytes: try message.serializedData()))
            } catch {
                fatalError(LibError.createDataSerializationFailedMessage(data: message))
            }
        }
    }

    func handleCharacteristicMessageResolve(result: @escaping FlutterResult, function: String = #function) -> Resolve {
        return { (obj: Any?) in
            guard let dict = obj as? [String: AnyObject], let message = CharacteristicMessage(bleData: dict) else {
                fatalError(LibError.createDataSerializationFailedMessage(data: obj))
            }
            do {
                result(FlutterStandardTypedData(bytes: try message.serializedData()))
            } catch {
                fatalError(LibError.createDataSerializationFailedMessage(data: message))
            }
        }
    }

    func handleReject(result: @escaping FlutterResult, function: String = #function) -> Reject {
        return { (code, message, error) in
            result(FlutterError(code: code ?? "Unknown", message: message, details: "requestMTUForDevice"))
        }
    }
}
