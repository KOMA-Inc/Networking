import Combine

protocol SystemConvertableError {
    init(from error: Error)
}

extension Publisher {
    func mapToErrorType<E>(_ type: E.Type) -> Publishers.MapError<Self, E> where E: SystemConvertableError {
        mapError { error -> E in
            return if let error = error as? E {
                error
            } else {
                E.init(from: error)
            }
        }
    }
}
