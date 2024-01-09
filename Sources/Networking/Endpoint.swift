import Foundation

public protocol Endpoint {

    var host: String { get }

    var path: String { get }

    var method: HTTPMethod { get }

    var body: Encodable? { get }

    var queryItems: [URLQueryItem]? { get }
}

public extension Endpoint {

    var queryItems: [URLQueryItem]? {
        nil
    }
}
