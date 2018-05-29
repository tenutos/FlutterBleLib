import Foundation
import Flutter

class BaseStreamHandler: NSObject, FlutterStreamHandler {
    private(set) var sink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    func sendError(_ error: FlutterError) {
        sink?(error)
    }
}
