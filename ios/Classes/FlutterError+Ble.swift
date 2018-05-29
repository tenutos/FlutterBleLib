import Foundation
import Flutter

extension FlutterError {
    static func clientAlreadyCreated() -> FlutterError {
        return FlutterError(code: "1002", message: "Cannot createClient when one is already existing. Please first call destroyClient.", details: nil)
    }
    static func clientNotCreated() -> FlutterError {
        return FlutterError(code: "1003", message: "Client not created. Please first call createClient.", details: nil)
    }
    static func cannotHandleMethod(methodName: String) -> FlutterError {
        return FlutterError(code: "1004", message: "Cannot handle method with name: \(methodName)", details: nil)
    }
}
