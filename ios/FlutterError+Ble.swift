import Foundation

extension FlutterError {
    static func dataSerializationFailed(data: Any?, details: Any? = nil) -> FlutterError {
        return FlutterError(code: "1000", message: "Could not serialize object: \(String(describing: data))", details: details)
    }
    static func incorrectMethodArguments(methodName: String, arguments: Any?) -> FlutterError {
        return FlutterError(code: "1001", message: "Invalid method call: \(methodName), arguments: \(String(describing: arguments))", details: nil)
    }
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
