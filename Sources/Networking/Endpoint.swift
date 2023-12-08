import Foundation

public protocol Endpoint {

    var host: String { get }

    var path: String { get }

    var method: HTTPMethod { get }

    var body: Encodable? { get }

    var parameters: [String: Any]? { get }
}

public extension Endpoint {

    var parameters: [String: Any]? {
        nil
    }
}
