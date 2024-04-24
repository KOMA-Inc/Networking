import Combine
import Foundation

public protocol AnyHTTPURLResponse {

    var urlResponse: URLResponse { get }

    /// The expected length of the response’s content
    var expectedContentLength: Int64 { get }

    /// A suggested filename for the response data
    var suggestedFilename: String? { get }

    /// The MIME type of the response
    var mimeType: String? { get }

    /// The name of the text encoding provided by the response’s originating source
    var textEncodingName: String? { get }

    // The URL for the response
    var url: URL? { get }

    /// Returns the value that corresponds to the given header field
    func value(forHTTPHeaderField: String) -> String?

    /// All HTTP header fields of the response
    var allHeaderFields: [AnyHashable : Any] { get }

    /// Returns a localized string corresponding to a specified HTTP status code
    static func localizedString(for statusCode: Int) -> String

    /// The response’s HTTP status code
    var statusCode: Int { get }
}

extension HTTPURLResponse: AnyHTTPURLResponse {

    public static func localizedString(for statusCode: Int) -> String {
        HTTPURLResponse.localizedString(forStatusCode: statusCode)
    }

    public var urlResponse: URLResponse {
        self
    }
}

public protocol Mocker: AnyObject {

    func setURLSession(_ urlSession: URLSession)
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(Data, AnyHTTPURLResponse), URLError>
}

