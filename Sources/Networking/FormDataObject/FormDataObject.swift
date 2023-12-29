import Foundation

public enum FormDataObject {
    case imageJPG(name: String, data: Data, filename: String)
    case string(name: String, value: String)
    case text(name: String, data: Data, filename: String)
    case custom(name: String, data: Data, filename: String, mimeType: String)
}
