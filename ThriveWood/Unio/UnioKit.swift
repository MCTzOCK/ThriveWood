//
//  UnioKit.swift
//  Drivo
//
//  Created by Ben Siebert on 23.08.26.
//
import Foundation
import CryptoKit

// MARK: - Constants

public enum UnioConstants {
    public static let protocolVersion = 1
    public static let defaultAppGroupIdentifier =
        "group.com.bensiebert.apps"
}

// MARK: - Universal JSON

public enum UnioJSON: Codable, Sendable, Equatable {
    case null
    case bool(Bool)
    case integer(Int64)
    case number(Double)
    case string(String)
    case array([UnioJSON])
    case object([String: UnioJSON])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([UnioJSON].self) {
            self = .array(value)
        } else if let value = try? container.decode(
            [String: UnioJSON].self
        ) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()

        case .bool(let value):
            try container.encode(value)

        case .integer(let value):
            try container.encode(value)

        case .number(let value):
            try container.encode(value)

        case .string(let value):
            try container.encode(value)

        case .array(let value):
            try container.encode(value)

        case .object(let value):
            try container.encode(value)
        }
    }

    public var objectValue: [String: UnioJSON]? {
        guard case .object(let value) = self else {
            return nil
        }

        return value
    }

    public var arrayValue: [UnioJSON]? {
        guard case .array(let value) = self else {
            return nil
        }

        return value
    }

    public var stringValue: String? {
        switch self {
        case .string(let value):
            return value

        default:
            return nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case .integer(let value):
            return Double(value)

        case .number(let value):
            return value

        default:
            return nil
        }
    }

    public var integerValue: Int64? {
        switch self {
        case .integer(let value):
            return value

        case .number(let value):
            return Int64(value)

        default:
            return nil
        }
    }

    public var boolValue: Bool? {
        guard case .bool(let value) = self else {
            return nil
        }

        return value
    }

    public var dateValue: Date? {
        guard let stringValue else {
            return nil
        }

        return UnioCoding.dateFormatter.date(from: stringValue)
    }

    public subscript(key: String) -> UnioJSON? {
        objectValue?[key]
    }

    public func value(at path: [String]) -> UnioJSON? {
        path.reduce(Optional(self)) { current, component in
            current?.objectValue?[component]
        }
    }
}

// MARK: - Coding

public enum UnioCoding {
    public static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }()

    public static func makeEncoder(
        prettyPrinted: Bool = false
    ) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(dateFormatter.string(from: date))
        }

        if prettyPrinted {
            encoder.outputFormatting = [
                .prettyPrinted,
                .sortedKeys,
                .withoutEscapingSlashes
            ]
        } else {
            encoder.outputFormatting = [
                .sortedKeys,
                .withoutEscapingSlashes
            ]
        }

        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            guard let date = dateFormatter.date(from: value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO 8601 date: \(value)"
                )
            }

            return date
        }

        return decoder
    }

    public static func toJSON<Value: Encodable>(
        _ value: Value
    ) throws -> UnioJSON {
        let data = try makeEncoder().encode(value)
        return try makeDecoder().decode(UnioJSON.self, from: data)
    }

    public static func decode<Value: Decodable>(
        _ type: Value.Type,
        from json: UnioJSON
    ) throws -> Value {
        let data = try makeEncoder().encode(json)
        return try makeDecoder().decode(type, from: data)
    }

    public static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - Schema

public enum UnioValueType: String, Codable, Sendable {
    case string
    case integer
    case number
    case boolean
    case date
    case object
    case array
    case identifier
    case latitude
    case longitude
    case unknown
}

public enum UnioCardinality: String, Codable, Sendable {
    case one
    case optional
    case many
}

public struct UnioFieldDefinition: Codable, Sendable {
    public let path: [String]
    public let title: String
    public let valueType: UnioValueType
    public let semanticType: String?
    public let unit: String?
    public let currency: String?
    public let description: String?
    public let isSensitive: Bool

    public init(
        path: [String],
        title: String,
        valueType: UnioValueType,
        semanticType: String? = nil,
        unit: String? = nil,
        currency: String? = nil,
        description: String? = nil,
        isSensitive: Bool = false
    ) {
        self.path = path
        self.title = title
        self.valueType = valueType
        self.semanticType = semanticType
        self.unit = unit
        self.currency = currency
        self.description = description
        self.isSensitive = isSensitive
    }
}

public struct UnioRelationDefinition: Codable, Sendable {
    public let path: [String]
    public let relationType: String
    public let targetEntityType: String
    public let targetDatasetID: String?
    public let cardinality: UnioCardinality

    public init(
        path: [String],
        relationType: String,
        targetEntityType: String,
        targetDatasetID: String? = nil,
        cardinality: UnioCardinality = .optional
    ) {
        self.path = path
        self.relationType = relationType
        self.targetEntityType = targetEntityType
        self.targetDatasetID = targetDatasetID
        self.cardinality = cardinality
    }
}

public struct UnioDatasetSchema: Codable, Sendable {
    public let schemaVersion: Int
    public let datasetID: String
    public let entityType: String
    public let title: String
    public let description: String?
    public let primaryKeyPath: [String]
    public let createdAtPath: [String]?
    public let updatedAtPath: [String]?
    public let deletedAtPath: [String]?
    public let fields: [UnioFieldDefinition]
    public let relations: [UnioRelationDefinition]

    public init(
        schemaVersion: Int = 1,
        datasetID: String,
        entityType: String,
        title: String,
        description: String? = nil,
        primaryKeyPath: [String] = ["id"],
        createdAtPath: [String]? = nil,
        updatedAtPath: [String]? = nil,
        deletedAtPath: [String]? = nil,
        fields: [UnioFieldDefinition],
        relations: [UnioRelationDefinition] = []
    ) {
        self.schemaVersion = schemaVersion
        self.datasetID = datasetID
        self.entityType = entityType
        self.title = title
        self.description = description
        self.primaryKeyPath = primaryKeyPath
        self.createdAtPath = createdAtPath
        self.updatedAtPath = updatedAtPath
        self.deletedAtPath = deletedAtPath
        self.fields = fields
        self.relations = relations
    }

    public func fields(
        withSemanticType semanticType: String
    ) -> [UnioFieldDefinition] {
        fields.filter {
            $0.semanticType == semanticType
        }
    }
}

// MARK: - Manifest

public struct UnioSource: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let bundleIdentifier: String?
    public let appVersion: String?
    public let metadata: [String: UnioJSON]

    public init(
        id: String,
        displayName: String,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        appVersion: String? = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String,
        metadata: [String: UnioJSON] = [:]
    ) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.appVersion = appVersion
        self.metadata = metadata
    }
}

public struct UnioExportDescriptor: Codable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let mode: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        mode: String = "full"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.mode = mode
    }
}

public struct UnioDatasetDescriptor: Codable, Sendable {
    public let id: String
    public let entityType: String
    public let title: String
    public let dataFile: String
    public let schemaFile: String
    public let recordCount: Int
    public let byteCount: Int
    public let sha256: String
}

public struct UnioAssetDescriptor: Codable, Sendable {
    public let relativePath: String
    public let contentType: String?
    public let byteCount: Int
    public let sha256: String
}

public struct UnioManifest: Codable, Sendable {
    public let protocolVersion: Int
    public let source: UnioSource
    public let export: UnioExportDescriptor
    public let datasets: [UnioDatasetDescriptor]
    public let assets: [UnioAssetDescriptor]
}

public struct UnioCurrentExportPointer: Codable, Sendable {
    public let exportID: UUID
    public let updatedAt: Date
}

// MARK: - Export input

public struct UnioDatasetExport: Sendable {
    public let id: String
    public let entityType: String
    public let title: String
    public let schema: UnioDatasetSchema

    fileprivate let jsonLines: Data
    fileprivate let recordCount: Int

    public init<Record: Encodable & Sendable>(
        id: String,
        entityType: String,
        title: String,
        schema: UnioDatasetSchema,
        records: [Record]
    ) throws {
        guard id == schema.datasetID else {
            throw UnioError.schemaDatasetMismatch(
                datasetID: id,
                schemaDatasetID: schema.datasetID
            )
        }

        guard entityType == schema.entityType else {
            throw UnioError.schemaEntityMismatch(
                entityType: entityType,
                schemaEntityType: schema.entityType
            )
        }

        let encoder = UnioCoding.makeEncoder()
        var output = Data()

        for record in records {
            let line = try encoder.encode(record)
            output.append(line)
            output.append(0x0A)
        }

        self.id = id
        self.entityType = entityType
        self.title = title
        self.schema = schema
        self.jsonLines = output
        self.recordCount = records.count
    }
}

public struct UnioAssetExport: Sendable {
    public let relativePath: String
    public let contentType: String?
    public let data: Data

    public init(
        relativePath: String,
        contentType: String? = nil,
        data: Data
    ) {
        self.relativePath = relativePath
        self.contentType = contentType
        self.data = data
    }
}

// MARK: - Errors

public enum UnioError: LocalizedError {
    case appGroupUnavailable(String)
    case invalidIdentifier(String)
    case invalidRelativePath(String)
    case schemaDatasetMismatch(
        datasetID: String,
        schemaDatasetID: String
    )
    case schemaEntityMismatch(
        entityType: String,
        schemaEntityType: String
    )
    case sourceNotFound(String)
    case exportNotFound(UUID)
    case datasetNotFound(String)
    case checksumMismatch(String)
    case unsupportedProtocolVersion(Int)
    case malformedRecord(
        datasetID: String,
        line: Int
    )

    public var errorDescription: String? {
        switch self {
        case .appGroupUnavailable(let identifier):
            return "App Group unavailable: \(identifier)"

        case .invalidIdentifier(let identifier):
            return "Invalid Unio identifier: \(identifier)"

        case .invalidRelativePath(let path):
            return "Invalid relative path: \(path)"

        case .schemaDatasetMismatch(
            let datasetID,
            let schemaDatasetID
        ):
            return "Dataset \(datasetID) uses schema for \(schemaDatasetID)"

        case .schemaEntityMismatch(
            let entityType,
            let schemaEntityType
        ):
            return "Entity \(entityType) uses schema for \(schemaEntityType)"

        case .sourceNotFound(let sourceID):
            return "Unio source not found: \(sourceID)"

        case .exportNotFound(let exportID):
            return "Unio export not found: \(exportID)"

        case .datasetNotFound(let datasetID):
            return "Unio dataset not found: \(datasetID)"

        case .checksumMismatch(let file):
            return "Checksum mismatch: \(file)"

        case .unsupportedProtocolVersion(let version):
            return "Unsupported Unio protocol version: \(version)"

        case .malformedRecord(let datasetID, let line):
            return "Malformed record in \(datasetID), line \(line)"
        }
    }
}

// MARK: - Storage

private struct UnioStorage: Sendable {
    let rootURL: URL

    init(appGroupIdentifier: String) throws {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw UnioError.appGroupUnavailable(appGroupIdentifier)
        }

        rootURL = containerURL
            .appendingPathComponent(
                "Unio",
                isDirectory: true
            )
            .appendingPathComponent(
                "v1",
                isDirectory: true
            )
            .appendingPathComponent(
                "sources",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
    }

    func sourceURL(_ sourceID: String) throws -> URL {
        try validateIdentifier(sourceID)

        return rootURL.appendingPathComponent(
            sourceID,
            isDirectory: true
        )
    }

    func exportsURL(_ sourceID: String) throws -> URL {
        try sourceURL(sourceID).appendingPathComponent(
            "exports",
            isDirectory: true
        )
    }

    func exportURL(
        sourceID: String,
        exportID: UUID
    ) throws -> URL {
        try exportsURL(sourceID).appendingPathComponent(
            exportID.uuidString,
            isDirectory: true
        )
    }

    func pointerURL(_ sourceID: String) throws -> URL {
        try sourceURL(sourceID).appendingPathComponent(
            "current.json"
        )
    }

    func validateIdentifier(_ identifier: String) throws {
        let allowed = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "-_.")
        )

        guard
            !identifier.isEmpty,
            identifier.rangeOfCharacter(
                from: allowed.inverted
            ) == nil,
            identifier != ".",
            identifier != ".."
        else {
            throw UnioError.invalidIdentifier(identifier)
        }
    }

    func validateRelativePath(_ path: String) throws {
        let components = NSString(string: path).pathComponents

        guard
            !path.isEmpty,
            !path.hasPrefix("/"),
            !components.contains(".."),
            !components.contains(".")
        else {
            throw UnioError.invalidRelativePath(path)
        }
    }
}

// MARK: - Exporter

public actor UnioExporter {
    private let storage: UnioStorage
    private let retainedExportCount: Int

    public init(
        appGroupIdentifier: String =
            UnioConstants.defaultAppGroupIdentifier,
        retainedExportCount: Int = 2
    ) throws {
        storage = try UnioStorage(
            appGroupIdentifier: appGroupIdentifier
        )
        self.retainedExportCount = max(1, retainedExportCount)
    }

    @discardableResult
    public func export(
        source: UnioSource,
        datasets: [UnioDatasetExport],
        assets: [UnioAssetExport] = []
    ) throws -> UnioManifest {
        try storage.validateIdentifier(source.id)

        var datasetIDs = Set<String>()

        for dataset in datasets {
            try storage.validateIdentifier(dataset.id)

            guard datasetIDs.insert(dataset.id).inserted else {
                throw UnioError.invalidIdentifier(
                    "Duplicate dataset: \(dataset.id)"
                )
            }
        }

        let exportDescriptor = UnioExportDescriptor()
        let exportURL = try storage.exportURL(
            sourceID: source.id,
            exportID: exportDescriptor.id
        )

        try FileManager.default.createDirectory(
            at: exportURL,
            withIntermediateDirectories: true
        )

        do {
            let manifest = try writeExport(
                source: source,
                descriptor: exportDescriptor,
                datasets: datasets,
                assets: assets,
                exportURL: exportURL
            )

            try activate(
                exportID: exportDescriptor.id,
                sourceID: source.id
            )

            try cleanupOldExports(
                sourceID: source.id,
                keeping: exportDescriptor.id
            )

            return manifest
        } catch {
            try? FileManager.default.removeItem(at: exportURL)
            throw error
        }
    }

    public func removeExport(for sourceID: String) throws {
        let sourceURL = try storage.sourceURL(sourceID)

        guard FileManager.default.fileExists(
            atPath: sourceURL.path
        ) else {
            return
        }

        try FileManager.default.removeItem(at: sourceURL)
    }

    private func writeExport(
        source: UnioSource,
        descriptor: UnioExportDescriptor,
        datasets: [UnioDatasetExport],
        assets: [UnioAssetExport],
        exportURL: URL
    ) throws -> UnioManifest {
        let datasetsURL = exportURL.appendingPathComponent(
            "datasets",
            isDirectory: true
        )

        let schemasURL = exportURL.appendingPathComponent(
            "schemas",
            isDirectory: true
        )

        let assetsURL = exportURL.appendingPathComponent(
            "assets",
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: datasetsURL,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: schemasURL,
            withIntermediateDirectories: true
        )

        var datasetDescriptors: [UnioDatasetDescriptor] = []

        for dataset in datasets {
            let dataFile = "datasets/\(dataset.id).jsonl"
            let schemaFile = "schemas/\(dataset.id).json"

            let dataURL = exportURL.appendingPathComponent(dataFile)
            let schemaURL = exportURL.appendingPathComponent(
                schemaFile
            )

            try dataset.jsonLines.write(
                to: dataURL,
                options: [
                    .atomic,
                    .completeFileProtectionUnlessOpen
                ]
            )

            let schemaData = try UnioCoding.makeEncoder(
                prettyPrinted: true
            ).encode(dataset.schema)

            try schemaData.write(
                to: schemaURL,
                options: [
                    .atomic,
                    .completeFileProtectionUnlessOpen
                ]
            )

            datasetDescriptors.append(
                UnioDatasetDescriptor(
                    id: dataset.id,
                    entityType: dataset.entityType,
                    title: dataset.title,
                    dataFile: dataFile,
                    schemaFile: schemaFile,
                    recordCount: dataset.recordCount,
                    byteCount: dataset.jsonLines.count,
                    sha256: UnioCoding.sha256(
                        dataset.jsonLines
                    )
                )
            )
        }

        var assetDescriptors: [UnioAssetDescriptor] = []

        if !assets.isEmpty {
            try FileManager.default.createDirectory(
                at: assetsURL,
                withIntermediateDirectories: true
            )
        }

        for asset in assets {
            try storage.validateRelativePath(
                asset.relativePath
            )

            let relativePath =
                "assets/\(asset.relativePath)"

            let assetURL = exportURL.appendingPathComponent(
                relativePath
            )

            try FileManager.default.createDirectory(
                at: assetURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            try asset.data.write(
                to: assetURL,
                options: [
                    .atomic,
                    .completeFileProtectionUnlessOpen
                ]
            )

            assetDescriptors.append(
                UnioAssetDescriptor(
                    relativePath: relativePath,
                    contentType: asset.contentType,
                    byteCount: asset.data.count,
                    sha256: UnioCoding.sha256(asset.data)
                )
            )
        }

        let manifest = UnioManifest(
            protocolVersion: UnioConstants.protocolVersion,
            source: source,
            export: descriptor,
            datasets: datasetDescriptors,
            assets: assetDescriptors
        )

        let manifestData = try UnioCoding.makeEncoder(
            prettyPrinted: true
        ).encode(manifest)

        try manifestData.write(
            to: exportURL.appendingPathComponent(
                "manifest.json"
            ),
            options: [
                .atomic,
                .completeFileProtectionUnlessOpen
            ]
        )

        return manifest
    }

    private func activate(
        exportID: UUID,
        sourceID: String
    ) throws {
        let pointer = UnioCurrentExportPointer(
            exportID: exportID,
            updatedAt: Date()
        )

        let data = try UnioCoding.makeEncoder(
            prettyPrinted: true
        ).encode(pointer)

        try FileManager.default.createDirectory(
            at: try storage.sourceURL(sourceID),
            withIntermediateDirectories: true
        )

        try data.write(
            to: storage.pointerURL(sourceID),
            options: [
                .atomic,
                .completeFileProtectionUnlessOpen
            ]
        )
    }

    private func cleanupOldExports(
        sourceID: String,
        keeping currentExportID: UUID
    ) throws {
        let exportsURL = try storage.exportsURL(sourceID)

        let URLs = try FileManager.default.contentsOfDirectory(
            at: exportsURL,
            includingPropertiesForKeys: [
                .contentModificationDateKey
            ],
            options: [.skipsHiddenFiles]
        )

        let sorted = URLs.sorted { lhs, rhs in
            let lhsDate = try? lhs.resourceValues(
                forKeys: [.contentModificationDateKey]
            ).contentModificationDate

            let rhsDate = try? rhs.resourceValues(
                forKeys: [.contentModificationDateKey]
            ).contentModificationDate

            return (lhsDate ?? .distantPast) >
                (rhsDate ?? .distantPast)
        }

        let retained = Set(
            sorted.prefix(retainedExportCount).map(\.lastPathComponent)
        ).union([currentExportID.uuidString])

        for URL in sorted where !retained.contains(
            URL.lastPathComponent
        ) {
            try? FileManager.default.removeItem(at: URL)
        }
    }
}

// MARK: - Reader models

public struct UnioInstalledSource: Sendable, Identifiable {
    public var id: String {
        manifest.source.id
    }

    public let manifest: UnioManifest
    public let exportURL: URL
}

public struct UnioDiscoveryIssue: Sendable, Identifiable {
    public let id = UUID()
    public let sourceDirectory: String
    public let message: String
}

public struct UnioDiscoveryResult: Sendable {
    public let sources: [UnioInstalledSource]
    public let issues: [UnioDiscoveryIssue]
}

public struct UnioDatasetReadIssue: Sendable, Identifiable {
    public let id = UUID()
    public let line: Int?
    public let message: String
}

public struct UnioDatasetContent: Sendable {
    public let source: UnioSource
    public let descriptor: UnioDatasetDescriptor
    public let schema: UnioDatasetSchema
    public let records: [UnioJSON]
    public let issues: [UnioDatasetReadIssue]
}

public struct UnioLoadedRecord: Sendable, Identifiable {
    public let source: UnioSource
    public let dataset: UnioDatasetDescriptor
    public let schema: UnioDatasetSchema
    public let value: UnioJSON

    public var id: String {
        let localID = value.value(
            at: schema.primaryKeyPath
        )?.stringValue ?? UUID().uuidString

        return "\(source.id):\(dataset.id):\(localID)"
    }

    public func value(at path: [String]) -> UnioJSON? {
        value.value(at: path)
    }

    public func values(
        withSemanticType semanticType: String
    ) -> [UnioJSON] {
        schema.fields(
            withSemanticType: semanticType
        ).compactMap {
            value.value(at: $0.path)
        }
    }

    public func firstValue(
        withSemanticType semanticType: String
    ) -> UnioJSON? {
        values(withSemanticType: semanticType).first
    }
}

public struct UnioCatalog: Sendable {
    public let sources: [UnioInstalledSource]
    public let datasets: [UnioDatasetContent]
    public let discoveryIssues: [UnioDiscoveryIssue]

    public var records: [UnioLoadedRecord] {
        datasets.flatMap { content in
            content.records.map { record in
                UnioLoadedRecord(
                    source: content.source,
                    dataset: content.descriptor,
                    schema: content.schema,
                    value: record
                )
            }
        }
    }

    public func records(
        fromSource sourceID: String
    ) -> [UnioLoadedRecord] {
        records.filter {
            $0.source.id == sourceID
        }
    }

    public func records(
        entityType: String
    ) -> [UnioLoadedRecord] {
        records.filter {
            $0.dataset.entityType == entityType
        }
    }

    public func records(
        datasetID: String,
        sourceID: String? = nil
    ) -> [UnioLoadedRecord] {
        records.filter { record in
            guard record.dataset.id == datasetID else {
                return false
            }

            guard let sourceID else {
                return true
            }

            return record.source.id == sourceID
        }
    }

    public func decode<Value: Decodable>(
        _ type: Value.Type,
        record: UnioLoadedRecord
    ) throws -> Value {
        try UnioCoding.decode(type, from: record.value)
    }
}

// MARK: - Reader

public actor UnioReader {
    private let storage: UnioStorage

    public init(
        appGroupIdentifier: String =
            UnioConstants.defaultAppGroupIdentifier
    ) throws {
        storage = try UnioStorage(
            appGroupIdentifier: appGroupIdentifier
        )
    }

    public func discover() -> UnioDiscoveryResult {
        var sources: [UnioInstalledSource] = []
        var issues: [UnioDiscoveryIssue] = []

        let sourceDirectories: [URL]

        do {
            sourceDirectories = try FileManager.default
                .contentsOfDirectory(
                    at: storage.rootURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
        } catch {
            return UnioDiscoveryResult(
                sources: [],
                issues: [
                    UnioDiscoveryIssue(
                        sourceDirectory:
                            storage.rootURL.lastPathComponent,
                        message: error.localizedDescription
                    )
                ]
            )
        }

        for sourceDirectory in sourceDirectories {
            do {
                let sourceID = sourceDirectory.lastPathComponent
                let pointerData = try Data(
                    contentsOf: storage.pointerURL(sourceID)
                )

                let pointer = try UnioCoding.makeDecoder().decode(
                    UnioCurrentExportPointer.self,
                    from: pointerData
                )

                let exportURL = try storage.exportURL(
                    sourceID: sourceID,
                    exportID: pointer.exportID
                )

                let manifestData = try Data(
                    contentsOf: exportURL.appendingPathComponent(
                        "manifest.json"
                    )
                )

                let manifest = try UnioCoding.makeDecoder().decode(
                    UnioManifest.self,
                    from: manifestData
                )

                guard manifest.protocolVersion <=
                    UnioConstants.protocolVersion
                else {
                    throw UnioError.unsupportedProtocolVersion(
                        manifest.protocolVersion
                    )
                }

                sources.append(
                    UnioInstalledSource(
                        manifest: manifest,
                        exportURL: exportURL
                    )
                )
            } catch {
                issues.append(
                    UnioDiscoveryIssue(
                        sourceDirectory:
                            sourceDirectory.lastPathComponent,
                        message: error.localizedDescription
                    )
                )
            }
        }

        sources.sort {
            $0.manifest.source.displayName
                .localizedStandardCompare(
                    $1.manifest.source.displayName
                ) == .orderedAscending
        }

        return UnioDiscoveryResult(
            sources: sources,
            issues: issues
        )
    }

    public func loadDataset(
        _ descriptor: UnioDatasetDescriptor,
        from source: UnioInstalledSource,
        verifyChecksum: Bool = true
    ) throws -> UnioDatasetContent {
        let dataURL = try validatedURL(
            relativePath: descriptor.dataFile,
            inside: source.exportURL
        )

        let schemaURL = try validatedURL(
            relativePath: descriptor.schemaFile,
            inside: source.exportURL
        )

        let data = try Data(contentsOf: dataURL)

        if verifyChecksum {
            let checksum = UnioCoding.sha256(data)

            guard checksum == descriptor.sha256 else {
                throw UnioError.checksumMismatch(
                    descriptor.dataFile
                )
            }
        }

        let schemaData = try Data(contentsOf: schemaURL)
        let schema = try UnioCoding.makeDecoder().decode(
            UnioDatasetSchema.self,
            from: schemaData
        )

        var records: [UnioJSON] = []
        var issues: [UnioDatasetReadIssue] = []

        let lines = data.split(
            separator: 0x0A,
            omittingEmptySubsequences: true
        )

        for (index, line) in lines.enumerated() {
            do {
                let record = try UnioCoding.makeDecoder().decode(
                    UnioJSON.self,
                    from: Data(line)
                )

                records.append(record)
            } catch {
                issues.append(
                    UnioDatasetReadIssue(
                        line: index + 1,
                        message: error.localizedDescription
                    )
                )
            }
        }

        return UnioDatasetContent(
            source: source.manifest.source,
            descriptor: descriptor,
            schema: schema,
            records: records,
            issues: issues
        )
    }

    public func loadCatalog(
        verifyChecksums: Bool = true
    ) -> UnioCatalog {
        let discovery = discover()
        var datasets: [UnioDatasetContent] = []

        for source in discovery.sources {
            for descriptor in source.manifest.datasets {
                if let content = try? loadDataset(
                    descriptor,
                    from: source,
                    verifyChecksum: verifyChecksums
                ) {
                    datasets.append(content)
                }
            }
        }

        return UnioCatalog(
            sources: discovery.sources,
            datasets: datasets,
            discoveryIssues: discovery.issues
        )
    }

    public func loadAsset(
        _ descriptor: UnioAssetDescriptor,
        from source: UnioInstalledSource,
        verifyChecksum: Bool = true
    ) throws -> Data {
        let URL = try validatedURL(
            relativePath: descriptor.relativePath,
            inside: source.exportURL
        )

        let data = try Data(contentsOf: URL)

        if verifyChecksum {
            guard UnioCoding.sha256(data) == descriptor.sha256 else {
                throw UnioError.checksumMismatch(
                    descriptor.relativePath
                )
            }
        }

        return data
    }

    private func validatedURL(
        relativePath: String,
        inside exportURL: URL
    ) throws -> URL {
        try storage.validateRelativePath(relativePath)

        let root = exportURL.standardizedFileURL
        let candidate = exportURL
            .appendingPathComponent(relativePath)
            .standardizedFileURL

        guard candidate.path.hasPrefix(
            root.path + "/"
        ) else {
            throw UnioError.invalidRelativePath(relativePath)
        }

        return candidate
    }
}

// MARK: - Semantic helpers

public enum UnioSemanticType {
    public static let identifier = "identifier"

    public static let title = "title"
    public static let name = "name"

    public static let startTime = "startTime"
    public static let endTime = "endTime"
    public static let timestamp = "timestamp"
    public static let createdAt = "createdAt"
    public static let updatedAt = "updatedAt"

    public static let duration = "duration"
    public static let distance = "distance"
    public static let money = "money"
    public static let count = "count"

    public static let latitude = "latitude"
    public static let longitude = "longitude"
    public static let locationName = "locationName"

    public static let personName = "personName"
    public static let personIdentifier = "personIdentifier"
    public static let placeIdentifier = "placeIdentifier"
}

// MARK: - Basic correlation helpers

public struct UnioTimeRange: Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public func gap(to other: UnioTimeRange) -> TimeInterval {
        if end < other.start {
            return other.start.timeIntervalSince(end)
        }

        if other.end < start {
            return start.timeIntervalSince(other.end)
        }

        return 0
    }
}

public extension UnioLoadedRecord {
    var semanticTimeRange: UnioTimeRange? {
        let start =
            firstValue(
                withSemanticType: UnioSemanticType.startTime
            )?.dateValue
            ?? firstValue(
                withSemanticType: UnioSemanticType.timestamp
            )?.dateValue

        guard let start else {
            return nil
        }

        let end =
            firstValue(
                withSemanticType: UnioSemanticType.endTime
            )?.dateValue
            ?? start

        return UnioTimeRange(
            start: start,
            end: end
        )
    }

    var semanticCoordinate: (
        latitude: Double,
        longitude: Double
    )? {
        guard
            let latitude = firstValue(
                withSemanticType: UnioSemanticType.latitude
            )?.doubleValue,
            let longitude = firstValue(
                withSemanticType: UnioSemanticType.longitude
            )?.doubleValue
        else {
            return nil
        }

        return (
            latitude: latitude,
            longitude: longitude
        )
    }
}

public enum UnioCorrelation {
    public static func temporalCandidates(
        left: [UnioLoadedRecord],
        right: [UnioLoadedRecord],
        maximumGap: TimeInterval
    ) -> [(
        left: UnioLoadedRecord,
        right: UnioLoadedRecord,
        gap: TimeInterval
    )] {
        var candidates: [(
            left: UnioLoadedRecord,
            right: UnioLoadedRecord,
            gap: TimeInterval
        )] = []

        for leftRecord in left {
            guard let leftRange = leftRecord.semanticTimeRange else {
                continue
            }

            for rightRecord in right {
                guard let rightRange = rightRecord.semanticTimeRange else {
                    continue
                }

                let gap = leftRange.gap(to: rightRange)

                guard gap <= maximumGap else {
                    continue
                }

                candidates.append(
                    (
                        left: leftRecord,
                        right: rightRecord,
                        gap: gap
                    )
                )
            }
        }

        return candidates.sorted {
            $0.gap < $1.gap
        }
    }

    public static func distanceMeters(
        from first: (latitude: Double, longitude: Double),
        to second: (latitude: Double, longitude: Double)
    ) -> Double {
        let earthRadius = 6_371_000.0

        let latitude1 = first.latitude * .pi / 180
        let latitude2 = second.latitude * .pi / 180
        let latitudeDelta =
            (second.latitude - first.latitude) * .pi / 180
        let longitudeDelta =
            (second.longitude - first.longitude) * .pi / 180

        let a =
            sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(latitude1)
            * cos(latitude2)
            * sin(longitudeDelta / 2)
            * sin(longitudeDelta / 2)

        let c = 2 * atan2(
            sqrt(a),
            sqrt(1 - a)
        )

        return earthRadius * c
    }
}
