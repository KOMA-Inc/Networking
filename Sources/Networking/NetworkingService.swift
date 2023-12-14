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

    private let mocker: Mocker?

    // MARK: - Public interface

    public init(
        mocker: Mocker? = nil
    ) {
        self.mocker = mocker
    }

    public func request<T: Decodable>(
        _ endpoint: Endpoint
    ) -> AnyPublisher<T, APIError> {
        do {
            let request = try request(for: endpoint)
            logRequest(request, for: endpoint)
            return dataTaskPublisher(for: request)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .track { [weak self] data, response in
                    self?.track(endpoint: endpoint, data: data, response: response)
                }
                .tryMap { [weak self] data, response -> T in
                    guard let self else { throw APIError.noData }
                    do {
                        let container = try decoder(for: endpoint).decode(Container<T>.self, from: data)
                        if let error = container.error {
                            throw error
                        } else if let decodedData = container.data {
                            logResponse(response, for: request, for: endpoint, with: data)
                            return decodedData
                        } else {
                            throw APIError.noData
                        }
                    } catch {
                        logError(error, for: request, for: endpoint, with: response, with: data)
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

    private func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(Data, AnyHTTPURLResponse), URLError> {
        if let mocker {
            return mocker.dataTaskPublisher(for: request)
        } else {
            return URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { data, response in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(URLError.Code(rawValue: 1301))
                    }
                    return (data, httpResponse)
                }
                .mapError { error in
                    error as! URLError
                }
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
        response: AnyHTTPURLResponse
    ) {

    }

    open func logRequest(
        _ request: URLRequest,
        for endpoint: Endpoint
    ) {

    }

    open func logResponse(
        _ response: AnyHTTPURLResponse,
        for request: URLRequest,
        for endpoint: Endpoint,
        with data: Data
    ) {

    }

    open func logError(
        _ error: Swift.Error,
        for request: URLRequest,
        for endpoint: Endpoint,
        with response: AnyHTTPURLResponse,
        with data: Data
    ) {

    }
}
