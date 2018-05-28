import Foundation

class ObjectStreamHandler<T: Any>: BaseStreamHandler {
    func send(_ message: T?) {
        sink?(message)
    }
}
