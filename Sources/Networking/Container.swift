import Foundation

struct Container<DataType: Decodable>: Decodable {

    public let data: DataType?
    public let error: APIError?

    enum CodingKeys: String, CodingKey {
        case data
        case errors
        case error
        case code
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let code = try container.decodeIfPresent(Int.self, forKey: .code)
        let errors = try container.decodeIfPresent([ContainerMultipleError].self, forKey: .errors)
        let error = try container.decodeIfPresent(ContainerError.self, forKey: .error)

        if let errors, let code {
            self.error = .multiple(code: code, errors: errors)
        } else if let error, let code {
            self.error = .some(code: code, error: error)
        } else {
            self.error = nil
        }

        if self.error == nil {
            if let data = try? DataType(from: decoder) {
                self.data = data
            } else {
                if let embededContainer = try? container.decode(Container<DataType>.self, forKey: .data) {
                    data = embededContainer.data
                } else {
                    try data = container.decodeIfPresent(DataType.self, forKey: .data)
                }
            }
        } else {
            data = nil
        }
    }

    init(error: Error) {
        self.data = nil
        self.error = .init(error: error)
    }
}

public struct ContainerError: Decodable, Equatable {
    public let name: String
    public let message: String
}

public struct ContainerMultipleError: Decodable, Equatable {

    public let name: String
    public let messages: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case message
    }

    init(name: String, messages: [String]) {
        self.name = name
        self.messages = messages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        let messages = try? container.decode([String].self, forKey: .message)
        let message = try? container.decode(String.self, forKey: .message)

        if let messages {
            self.messages = messages
        } else if let message {
            self.messages = [message]
        } else {
            self.messages = []
        }
    }
}
