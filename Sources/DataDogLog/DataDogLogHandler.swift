import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

public struct DataDogLogHandler: LogHandler {
    public var metadata = Logger.Metadata()
    public var logLevel = Logger.Level.info
    public var label: String
    public var hostname: String?
    internal let key: String
    // Region for URL
    internal let region: Region

    var session: Session = URLSession.shared

    public init(
        label: String,
        key: String,
        hostname: String? = nil,
        region: Region = .US) {
        self.label = label
        self.key = key
        self.hostname = hostname
        self.region = region
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt) {
        let callsite: [String: Logger.MetadataValue] = ["callsite": "\(function):\(line)"]
        let logMetadata = metadata.map { $0.merging(callsite) { $1 } } ?? callsite
        let mergedMetadata = self.metadata.merging(logMetadata) { $1 }
        let ddMessage = Message(level: level, message: "\(message)")
        let log = Log(
            ddsource: source,
            ddtags: "\(mergedMetadata.prettified.map { "\($0)" } ?? "")",
            hostname: self.hostname ?? "",
            message: "\(ddMessage)",
            service: label,
            status: "\(level)")

        session.send(log, key: key, region: region) { result in
            if case .failure(let message) = result {
                debugPrint(message)
            }
        }
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set(newValue) {
            metadata[metadataKey] = newValue
        }
    }
}
