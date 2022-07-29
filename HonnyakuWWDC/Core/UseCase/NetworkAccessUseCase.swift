//  NetworkAccessUseCase.swift

import Foundation

protocol NetworkAccessUseCaseProtocol {
    func fetchText(url: URL) async throws -> String
    func postForm(url: URL, parameters: [String: String], files: [(key: String, filename: String, mime: String, data: Data)]) async throws -> Data
}

enum NetworkAccessUseCaseError: Error, LocalizedError {
    case postFormError(statusCode: Int?)
    case fetchError(statusCode: Int?)

    var errorDescription: String? {
        switch self {
        case let .postFormError(statusCode):
            return statusCode != nil ? "Post error(Status code:\(statusCode!))" : "Post error"
        case let .fetchError(statusCode):
            return statusCode != nil ? "Get error(Status code:\(statusCode!))" : "Get error"
        }
    }
}

final class NetworkAccessUseCase: NetworkAccessUseCaseProtocol {

    func fetchText(url: URL) async throws -> String {
        let (data, urlResponse) = try await URLSession.shared.data(from: url)
        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkAccessUseCaseError.postFormError(statusCode: nil)
        }
        guard case 200 ..< 400 = httpUrlResponse.statusCode else {
            print("Status code: \(httpUrlResponse.statusCode)")
            throw NetworkAccessUseCaseError.postFormError(statusCode: httpUrlResponse.statusCode)
        }
        let text = String(data: data, encoding: .utf8) ?? ""
        return text
    }

    func postForm(url: URL, parameters: [String: String], files: [(key: String, filename: String, mime: String, data: Data)]) async throws -> Data {
        let uniqueId = UUID().uuidString
        let boundary = "---------------------------\(uniqueId)"

        let header = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        let boundaryText = "--\(boundary)\r\n"

        var body: Data = boundaryText.data(using: .utf8)!
        for param in parameters {
            body += "Content-Disposition: form-data; name=\"\(param.key)\"\r\n".data(using: .utf8)!
            body += "\r\n".data(using: .utf8)!
            body += param.value.data(using: .utf8)!
            body += "\r\n".data(using: .utf8)!
            body += boundaryText.data(using: .utf8)!
        }
        for param in files {
            body += "Content-Disposition: form-data; name=\"\(param.key)\"; filename=\"\(param.filename)\"\r\n".data(using: .utf8)!
            body += "Content-Type: \(param.mime)\r\n".data(using: .utf8)!
            body += "\r\n".data(using: .utf8)!
            body += param.data
            body += "\r\n".data(using: .utf8)!
            body += boundaryText.data(using: .utf8)!
        }

        body += "--\(boundary)--\r\n".data(using: .utf8)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let urlConfig = URLSessionConfiguration.default
        urlConfig.httpAdditionalHeaders = header
        let session = Foundation.URLSession(configuration: urlConfig)

        let (data, urlResponse) = try await session.upload(for: request, from: body)
        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkAccessUseCaseError.postFormError(statusCode: nil)
        }
        guard case 200 ..< 400 = httpUrlResponse.statusCode else {
            print("Status code: \(httpUrlResponse.statusCode)")
            throw NetworkAccessUseCaseError.postFormError(statusCode: httpUrlResponse.statusCode)
        }
        return data
    }
}
