import CombinePlus
import Foundation

public protocol NetworkingService {
    associatedtype Endpoint: Networking.Endpoint

    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError>
}

open class NetworkService<Endpoint: Networking.Endpoint>: NetworkingService {

    // MARK: - Private properties

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Public interface

    public init() { }

    public func request<T: Decodable>(
        _ endpoint: Endpoint
    ) -> AnyPublisher<T, APIError> {
        do {
            let request = try request(for: endpoint)
            logRequest(request, for: endpoint)
            return URLSession.shared.dataTaskPublisher(for: request)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .track { [weak self] data, response in
                    self?.track(endpoint: endpoint, data: data, response: response)
                }
                .perform { [weak self] data, response in
                    self?.logResponse(response, for: endpoint, with: data)
                }
                .tryMap { [weak self] data, response -> T in
                    guard let self else { throw APIError.noData }
                    do {
                        let container = try decoder(for: endpoint).decode(Container<T>.self, from: data)
                        if let error = container.error {
                            throw error
                        } else if let data = container.data {
                            return data
                        } else {
                            throw APIError.noData
                        }
                    } catch {
                        logError(error, for: endpoint, with: response, with: data)
                        throw error
                    }
                }
                .mapToErrorType(APIError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .mapToErrorType(APIError.self)
                .eraseToAnyPublisher()
        }
    }

    private func request(for endpoint: Endpoint) throws -> URLRequest {
        guard
            let path = endpoint.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: endpoint.host + path) else {
            throw APIError.invalidBaseURL(endpoint.host + endpoint.path)
        }

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(for: endpoint)
        request.httpBody = endpoint.body.flatMap {
            try? encoder(for: endpoint).encode($0)
        }
        request.httpMethod = endpoint.method.rawValue

        return request
    }

    open func encoder(for endpoint: Endpoint) -> JSONEncoder {
        encoder
    }

    open func decoder(for endpoint: Endpoint) -> JSONDecoder {
        decoder
    }

    open func headers(for endpoint: Endpoint) -> [String: String]? {
        nil
    }

    open func track(
        endpoint: Endpoint,
        data: Data,
        response: URLResponse
    ) {

    }

    open func logRequest(
        _ request: URLRequest,
        for endpoint: Endpoint
    ) {

    }

    open func logResponse(
        _ response: URLResponse,
        for endpoint: Endpoint,
        with data: Data
    ) {

    }

    open func logError(
        _ error: Swift.Error,
        for endpoint: Endpoint,
        with response: URLResponse,
        with data: Data
    ) {

    }
}
