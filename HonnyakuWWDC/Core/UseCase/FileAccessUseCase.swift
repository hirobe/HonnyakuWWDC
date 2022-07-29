//  FileAccessUseCase.swift

import Foundation

protocol FileAccessUseCaseProtocol {
    func saveFileToDocuments(data: Data, path: String) throws
    func loadFileFromDocuments(path: String ) throws -> Data
    func documentDirectoryItems(path: String) throws -> [String]
    var documentDirectoryPath: String? { get }
}

enum FileAccessUseCaseError: Error, LocalizedError {
    case createFileError

    var errorDescription: String? {
        switch self {
        case .createFileError:
            return "Crate file error"
        }
    }
}

final class FileAccessUseCase: FileAccessUseCaseProtocol {
    func saveFileToDocuments(data: Data, path: String) throws {
        let fileManager = FileManager.default
        let documentDirectoryUrl = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        let url = documentDirectoryUrl.appendingPathComponent(path)

        try fileManager.createDirectory(atPath: url.deletingLastPathComponent().path, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(atPath: url.path)
        }
        let result = fileManager.createFile(atPath: url.path,
                                            contents: data,
                                            attributes: nil)
        if !result {
            throw FileAccessUseCaseError.createFileError
        }
    }

    func loadFileFromDocuments(path: String ) throws -> Data {
        let fileManager = FileManager.default
        let documentDirectoryUrl = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
        let url = documentDirectoryUrl.appendingPathComponent(path)
        let data = try Data(contentsOf: url)
        return data
    }

    func documentDirectoryItems(path: String) throws -> [String] {
        let fileManager = FileManager.default

        let documentDirectoryUrl = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)

        let url = documentDirectoryUrl.appendingPathComponent(path)
        return try fileManager.contentsOfDirectory(atPath: url.path)
    }

    var documentDirectoryPath: String? {
        let fileManager = FileManager.default
        let documentDirectoryUrl = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
        return documentDirectoryUrl?.path
    }
}
