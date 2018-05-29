import Foundation
import SwiftProtobuf
import Flutter

class MessageStreamHandler<T: Message>: BaseStreamHandler {
    func send(_ message: T) {
        guard let sink = sink else { return }
        do {
            let data = try message.serializedData()
            sink(FlutterStandardTypedData(bytes: data))
        } catch {
            fatalError(LibError.createDataSerializationFailedMessage(data: message))
        }
    }
}
