import Flutter
import UIKit
import SwiftProtobuf

enum LibError: Error {
    case flutterError(FlutterError)
}

public class SwiftFlutterBleLibPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Namespace.main.rawValue, binaryMessenger: registrar.messenger())

        let instance = SwiftFlutterBleLibPlugin(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    let scanDevicesHandler = MessageStreamHandler<ScanResultMessage>()
    let stateChangeHandler = ObjectStreamHandler<Int>()
    let deviceConnectionChangeHandler = MessageStreamHandler<BleDeviceMessage>()
    let monitorCharacteristicChangeHandler = MessageStreamHandler<MonitorCharacteristicMessage>()
    let restoreStateHandler = ObjectStreamHandler<[String: Any]>()

    var manager: BleClientManager?

    init(messenger: FlutterBinaryMessenger) {
        let scanDevicesChannel = FlutterEventChannel(name: Namespace.scanDevices.rawValue, binaryMessenger: messenger)
        let stateChangeChannel = FlutterEventChannel(name: Namespace.stateChange.rawValue, binaryMessenger: messenger)
        let deviceConnectionChangeChannel = FlutterEventChannel(name: Namespace.deviceConnectionChange.rawValue, binaryMessenger: messenger)
        let monitorCharacteristicChangeChannel = FlutterEventChannel(name: Namespace.monitorCharacteristicChange.rawValue, binaryMessenger: messenger)
        let restoreStateChannel = FlutterEventChannel(name: Namespace.restoreState.rawValue, binaryMessenger: messenger)

        scanDevicesChannel.setStreamHandler(scanDevicesHandler)
        stateChangeChannel.setStreamHandler(stateChangeHandler)
        deviceConnectionChangeChannel.setStreamHandler(deviceConnectionChangeHandler)
        monitorCharacteristicChangeChannel.setStreamHandler(monitorCharacteristicChangeHandler)
        restoreStateChannel.setStreamHandler(restoreStateHandler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try innerHandle(call, result: result)
        } catch LibError.flutterError(let error) {
            result(error)
        } catch {
            fatalError("Received unknown error \(error)")
        }
    }

    private func innerHandle(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        switch call.method {
        case Method.createClient.rawValue:
            try createClient(restoreIdentifierKey: call.arguments as? String, result: result)
        case Method.destroyClient.rawValue:
            destroyClient(result: result)
        case Method.setLogLevel.rawValue:
            try setLogLevel(arguments: call.arguments, result: result)
        case Method.cancelTransaction.rawValue:
            try cancelTransaction(arguments: call.arguments, result: result)
        case Method.logLevel.rawValue:
            try logLevel(result: result)
        case Method.state.rawValue:
            try state(result: result)
        case Method.startDeviceScan.rawValue:
            try startDeviceScan(arguments: call.arguments, result: result)
        case Method.stopDeviceScan.rawValue:
            try stopDeviceScan(result: result)
        case Method.requestMTUForDevice.rawValue:
            try requestMTUForDevice(arguments: call.arguments, result: result)
        case Method.readRSSIForDevice.rawValue:
            try readRSSIForDevice(arguments: call.arguments, result: result)
        case Method.connectToDevice.rawValue:
            try connectToDevice(arguments: call.arguments, result: result)
        case Method.cancelDeviceConnection.rawValue:
            try cancelDeviceConnection(arguments: call.arguments, result: result)
        case Method.isDeviceConnected.rawValue:
            try isDeviceConnected(arguments: call.arguments, result: result)
        case Method.discoverAllServicesAndCharacteristicsForDevice.rawValue:
            try discoverAllServicesAndCharacteristicsForDevice(arguments: call.arguments, result: result)
        case Method.servicesForDevice.rawValue:
            try servicesForDevice(arguments: call.arguments, result: result)
        case Method.characteristicsForDevice.rawValue:
            try characteristicsForDevice(arguments: call.arguments, result: result)
        case Method.characteristicsForService.rawValue:
            try characteristicsForService(arguments: call.arguments, result: result)
        case Method.writeCharacteristicForDevice.rawValue:
            try writeCharacteristicForDevice(arguments: call.arguments, result: result)
        case Method.writeCharacteristicForService.rawValue:
            try writeCharacteristicForService(arguments: call.arguments, result: result)
        case Method.writeCharacteristic.rawValue:
            try writeCharacteristic(arguments: call.arguments, result: result)
        case Method.readCharacteristicForDevice.rawValue:
            try readCharacteristicForDevice(arguments: call.arguments, result: result)
        case Method.readCharacteristicForService.rawValue:
            try readCharacteristicForService(arguments: call.arguments, result: result)
        case Method.readCharacteristic.rawValue:
            try readCharacteristic(arguments: call.arguments, result: result)
        case Method.monitorCharacteristicForDevice.rawValue:
            try monitorCharacteristicForDevice(arguments: call.arguments, result: result)
        case Method.monitorCharacteristicForService.rawValue:
            try monitorCharacteristicForService(arguments: call.arguments, result: result)
        case Method.monitorCharacteristic.rawValue:
            try monitorCharacteristic(arguments: call.arguments, result: result)
        default:
            throw LibError.flutterError(FlutterError.cannotHandleMethod(methodName: call.method))
        }
    }

    private func createClient(restoreIdentifierKey: String?, result: FlutterResult) throws {
        guard manager == nil else {
            throw LibError.flutterError(FlutterError.clientAlreadyCreated())
        }
        manager = BleClientManager(queue: DispatchQueue.main, restoreIdentifierKey: restoreIdentifierKey)
        manager?.delegate = self
        result(nil)
    }

    private func destroyClient(result: FlutterResult) {
        manager?.invalidate()
        manager = nil
        result(nil)
    }

    private func setLogLevel(arguments: Any?, result: FlutterResult) throws {
        guard let logLevel = arguments as? String else {
            throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.setLogLevel(logLevel.capitalized)
        result(nil)
    }

    private func logLevel(result: FlutterResult) throws {
        let manager = try ensureManagerCreated()
        let details = #function
        manager.logLevel { obj in
            guard let level = obj as? UInt8, let logLevel = LogLevelMessage(rawValue: Int(level)) else {
                result(FlutterError.dataSerializationFailed(data: obj, details: details))
                return
            }
            result(logLevel.rawValue)
        }
    }

    private func cancelTransaction(arguments: Any?, result: FlutterResult) throws {
        guard let transactionId = arguments as? String else {
            throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.cancelTransaction(transactionId)
        result(nil)
    }

    private func state(result: FlutterResult) throws {
        let manager = try ensureManagerCreated()
        manager.state { obj in
            guard let stateInt = obj as? Int, let state = BluetoothStateMessage(rawValue: stateInt) else {
                result(FlutterError.dataSerializationFailed(data: obj, details: "state"))
                return
            }
            result(state.rawValue)
        }
    }

    private func startDeviceScan(arguments: Any?, result: FlutterResult) throws {
        let message = try retrieveScanDataMessage(fromArguments: arguments)
        let manager = try ensureManagerCreated()
        // TODO: add handling options
        manager.startDeviceScan(message.uuids, options: nil)
        result(nil)
    }

    private func stopDeviceScan(result: FlutterResult) throws {
        let manager = try ensureManagerCreated()
        manager.stopDeviceScan()
        result(nil)
    }

    private func requestMTUForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let deviceId = dict["deviceId"] as? String,
            let mtu = dict["mtu"] as? Int,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.requestMTUForDevice(
            deviceId,
            mtu: mtu,
            transactionId: transactionId,
            resolve: handleDeviceMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func readRSSIForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let deviceId = dict["deviceId"] as? String,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.readRSSIForDevice(
            deviceId,
            transactionId:
            transactionId,
            resolve: handleDeviceMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func connectToDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        let message = try retrieveDeviceMessage(fromArguments: arguments)
        let manager = try ensureManagerCreated()
        // TODO:- add options support to connectToDevice
        manager.connectToDevice(message.id, options: nil, resolve: handleDeviceMessageResolve(result: result), reject: handleReject(result: result))
    }

    private func cancelDeviceConnection(arguments: Any?, result: @escaping FlutterResult) throws {
        let manager = try ensureManagerCreated()
        let deviceId = try retrieveDeviceId(fromArgument: arguments)
        manager.cancelDeviceConnection(deviceId, resolve: handleDeviceMessageResolve(result: result), reject: handleReject(result: result))
    }

    private func isDeviceConnected(arguments: Any?, result: @escaping FlutterResult) throws {
        let manager = try ensureManagerCreated()
        let deviceId = try retrieveDeviceId(fromArgument: arguments)
        manager.isDeviceConnected(deviceId, resolve: { obj in
            guard let isConnected = obj as? Bool else {
                result(FlutterError.dataSerializationFailed(data: obj))
                return
            }
            result(isConnected)
        }, reject: handleReject(result: result))
    }

    private func discoverAllServicesAndCharacteristicsForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        let manager = try ensureManagerCreated()
        let deviceId = try retrieveDeviceId(fromArgument: arguments)
        manager.discoverAllServicesAndCharacteristicsForDevice(
            deviceId,
            resolve: handleDeviceMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func servicesForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        let manager = try ensureManagerCreated()
        let deviceId = try retrieveDeviceId(fromArgument: arguments)
        manager.servicesForDevice(deviceId, resolve: handleServicesMessageResolve(result: result), reject: handleReject(result: result))
    }

    private func characteristicsForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let deviceId = dict["deviceId"] as? String,
            let serviceUUID = dict["serviceUUID"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.characteristicsForDevice(
            deviceId,
            serviceUUID: serviceUUID,
            resolve: handleCharacteristicMessagesResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func characteristicsForService(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let serviceIdentifierString = dict["serviceIdentifier"] as? String,
            let serviceIdentifier = Double(serviceIdentifierString) else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.characteristicsForService(
            serviceIdentifier,
            resolve: handleCharacteristicMessagesResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func writeCharacteristicForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let deviceId = dict["deviceId"] as? String,
            let serviceUUID = dict["serviceUUID"] as? String,
            let characteristicUUID = dict["characteristicUUID"] as? String,
            let valueBase64 = dict["valueBase64"] as? String,
            let response = dict["response"] as? Bool,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.writeCharacteristicForDevice(
            deviceId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            valueBase64: valueBase64,
            response: response,
            transactionId: transactionId,
            resolve: handleCharacteristicMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func writeCharacteristicForService(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let serviceIdentifier = dict["serviceIdentifier"] as? Double,
            let characteristicUUID = dict["characteristicUUID"] as? String,
            let valueBase64 = dict["valueBase64"] as? String,
            let response = dict["response"] as? Bool,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.writeCharacteristicForService(
            serviceIdentifier,
            characteristicUUID: characteristicUUID,
            valueBase64: valueBase64,
            response: response,
            transactionId: transactionId,
            resolve: handleCharacteristicMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func writeCharacteristic(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let characteristicIdentifier = dict["characteristicIdentifier"] as? Double,
            let valueBase64 = dict["valueBase64"] as? String,
            let response = dict["response"] as? Bool,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.writeCharacteristic(
            characteristicIdentifier,
            valueBase64: valueBase64,
            response: response,
            transactionId: transactionId,
            resolve: handleCharacteristicMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func readCharacteristicForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let deviceId = dict["deviceId"] as? String,
            let serviceUUID = dict["serviceUUID"] as? String,
            let characteristicUUID = dict["characteristicUUID"] as? String,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.readCharacteristicForDevice(
            deviceId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            transactionId: transactionId,
            resolve: handleCharacteristicMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func readCharacteristicForService(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let serviceIdentifier = dict["serviceIdentifier"] as? Double,
            let characteristicUUID = dict["characteristicUUID"] as? String,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.readCharacteristicForService(
            serviceIdentifier,
            characteristicUUID: characteristicUUID,
            transactionId: transactionId,
            resolve: handleCharacteristicMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func readCharacteristic(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let characteristicIdentifier = dict["characteristicIdentifier"] as? Double,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.readCharacteristic(
            characteristicIdentifier,
            transactionId: transactionId,
            resolve: handleCharacteristicMessageResolve(result: result),
            reject: handleReject(result: result)
        )
    }

    private func monitorCharacteristicForDevice(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let deviceId = dict["deviceId"] as? String,
            let serviceUUID = dict["serviceUUID"] as? String,
            let characteristicUUID = dict["characteristicUUID"] as? String,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.monitorCharacteristicForDevice(
            deviceId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            transactionId: transactionId,
            resolve: { _ in result(nil) },
            reject: handleReject(result: result)
        )
    }

    private func monitorCharacteristicForService(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let serviceIdentifier = dict["serviceIdentifier"] as? Double,
            let characteristicUUID = dict["characteristicUUID"] as? String,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.monitorCharacteristicForService(
            serviceIdentifier,
            characteristicUUID: characteristicUUID,
            transactionId: transactionId,
            resolve: { _ in result(nil) },
            reject: handleReject(result: result)
        )
    }

    private func monitorCharacteristic(arguments: Any?, result: @escaping FlutterResult) throws {
        guard let dict = arguments as? [String: AnyObject],
            let characteristicIdentifier = dict["characteristicIdentifier"] as? Double,
            let transactionId = dict["transactionId"] as? String else {
                throw LibError.flutterError(FlutterError.incorrectMethodArguments(methodName: #function, arguments: arguments))
        }
        let manager = try ensureManagerCreated()
        manager.monitorCharacteristic(
            characteristicIdentifier,
            transactionId: transactionId,
            resolve: { _ in result(nil) },
            reject: handleReject(result: result)
        )
    }
}

extension SwiftFlutterBleLibPlugin: BleClientManagerDelegate {
    public func dispatchEvent(_ name: String, value: Any) {
        switch name {
        case BleEvent.scanEvent:
            handleDispatchEvent(value: value, handler: scanDevicesHandler, createEventData: { (value) -> EventData<[String: AnyObject]>? in
                return EventData(value: value)
            }) { (data: [String: AnyObject]) -> ScanResultMessage? in
                return ScanResultMessage(bleData: data)
            }
        case BleEvent.stateChangeEvent:
            handleDispatchEvent(value: value, handler: stateChangeHandler, createEventData: { (value) -> EventData<[String: AnyObject]>? in
                return EventData(value: value)
            }) { (data: [String: AnyObject]) -> ScanResultMessage? in
                return ScanResultMessage(bleData: data)
            }

        }
        //    if([BleEvent.scanEvent isEqualToString: name]) {
        //        [_scanDevicesHandler handleScanDevice : [Converter convertToScanResultMessage:value]];
        //    } else if([BleEvent.stateChangeEvent isEqualToString: name]) {
        //        [_bluetoothStateHandler handleBluetoothState:[Converter convertToBleDataBluetoothStateMessageFromString:value]];
        //    } else if([BleEvent.disconnectionEvent isEqualToString: name]) {
        //        [_deviceConnectionChangeHandler handleDeviceConnectionState:[Converter convertToBleDeviceMessage:value]];
        //    } else if([BleEvent.readEvent isEqualToString: name]) {
        //        [_monitorCharacteristicHandler handleMonitorCharacteristic:[Converter conevrtToMonitorCharacteristicMessage:value]];
        //    } else if([BleEvent.restoreStateEvent isEqualToString:name]) {
        //        [_restoreStateHandler handleResoreState:value];
        //    }
    }

    private func handleDispatchEvent<T, M: Message>(value: Any, handler: MessageStreamHandler<M>, createEventData: (Any) -> EventData<T>?, createMessage: (T) -> M?){
        guard let eventData = createEventData(value) else {
            handler.sendError(FlutterError.dataSerializationFailed(data: value))
            return
        }
        if let error = eventData.error {
            handler.sendError(error)
        } else if let data = eventData.data {
            guard let message = createMessage(data) else {
                handler.sendError(FlutterError.dataSerializationFailed(data: data))
            }
            handler.send(message)
        } else {
            handler.sendError(FlutterError.dataSerializationFailed(data: value))
        }
    }
}
