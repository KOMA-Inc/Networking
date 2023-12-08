import Foundation

public enum APIError: LocalizedError {

    case invalidResponse
    case invalidBaseURL(String)
    case noData
    case system(Error)
    case some(code: Int, error: ContainerError)
    case multiple(code: Int, errors: [ContainerMultipleError])

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid response"
        case let .invalidBaseURL(url):
            "Invalid base URL \(url)"
        case .noData:
            "No data"
        case let .some(code, error):
            code.description + "\n" + error.name + "\n" + error.message
        case let .system(error):
            error.localizedDescription
        case let .multiple(code, errors):
            code.description + "\n\n" + errors.map { error in
                error.name + "\n" + error.messages.joined(separator: "; ")
            }.joined(separator: "\n\n")
        }
    }

    init(error: Error) {
        self = if let error = error as? APIError {
            error
        } else {
            .system(error)
        }
    }
}
