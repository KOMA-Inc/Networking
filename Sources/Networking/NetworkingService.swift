import CombinePlus
import Foundation

public protocol NetworkingService {
    associatedtype Endpoint: Networking.Endpoint

    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>
}

public class NetworkService<Endpoint: Networking.Endpoint>: NetworkingService {

    // MARK: - Private properties

    private let decoder = JSONDecoder()

    // MARK: - Public interface

    public init() { }

    public func request<T: Decodable>(
        _ endpoint: Endpoint
    ) -> AnyPublisher<T, Error> {
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
                .map { data, _ -> Data in
                    data
                }
                .decode(type: Container<T>.self, decoder: decoder(for: endpoint))
                .tryMap { container in
                    if let error = container.error {
                        throw error
                    } else if let data = container.data {
                        return data
                    } else {
                        throw APIError.noData
                    }
                }
                .onError { [weak self] error in
                    self?.logError(error, for: endpoint)
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
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
        request.httpBody = endpoint.body
        request.httpMethod = endpoint.method.rawValue

        return request
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
        for endpoint: Endpoint
    ) {

    }
}
