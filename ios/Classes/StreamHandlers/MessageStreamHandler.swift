import Foundation
import SwiftProtobuf

class MessageStreamHandler<T: Message>: BaseStreamHandler {
    func send(_ message: T) {
        guard let sink = sink else { return }
        do {
            let data = try message.serializedData()
            sink(data)
        } catch {
            sink(FlutterError.dataSerializationFailed(data: message, details: "MessageStreamHandler.send(_:)"))
        }
    }
}
