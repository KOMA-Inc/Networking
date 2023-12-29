import Foundation

public extension Endpoint {

    func stringDataObject(name: String, value: String) -> FormDataObject {
        .string(name: name, value: value)
    }

    func imageDataObject(
        name: String,
        data: Data,
        filename: String = "photo.jpg"
    ) -> FormDataObject {
        .imageJPG(name: name, data: data, filename: filename)
    }

    func multipartFormData(
        parameters: [FormDataObject],
        boundary: String
    ) -> Data? {
        var body = Data()

        parameters.forEach {
            switch $0 {

            case let .imageJPG(name, data, filename):
                createBody(
                    in: &body,
                    name: name,
                    boundary: boundary,
                    fileData: data,
                    mimeType: "image/jpg",
                    filename: filename
                )

            case let .string(name, value):
                createBody(
                    in: &body,
                    name: name,
                    value: value,
                    boundary: boundary
                )

            case let .text(name, data, filename):
                createBody(
                    in: &body,
                    name: name,
                    boundary: boundary,
                    fileData: data,
                    mimeType: "text/plain",
                    filename: filename
                )

            case let .custom(name, data, filename, mimeType):
                createBody(
                    in: &body,
                    name: name,
                    boundary: boundary,
                    fileData: data,
                    mimeType: mimeType,
                    filename: filename
                )
            }
        }

        finalize(body: &body, withBoundary: boundary)
        return body
    }
}

private extension Endpoint {
    func createBody(
        in body: inout Data,
        name: String,
        value: String,
        boundary: String
    ) {
        let boundaryPrefix = "--\(boundary)\r\n"

        body.append(boundaryPrefix)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.append("\(value)\r\n")
    }

    func createBody(
        in body: inout Data,
        name: String,
        boundary: String,
        fileData: Data,
        mimeType: String,
        filename: String
    ) {
        let boundaryPrefix = "--\(boundary)\r\n"

        body.append(boundaryPrefix)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
    }

    func finalize(body: inout Data, withBoundary boundary: String) {
        body.append("--".appending(boundary.appending("--")))
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(
            using: String.Encoding.utf8,
            allowLossyConversion: false
        ) {
            append(data)
        }
    }
}
