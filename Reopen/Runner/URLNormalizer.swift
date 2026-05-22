import Foundation

enum URLNormalizationError: Error, Equatable {
    case emptyURL
    case unsupportedScheme(String)
    case missingHost
    case invalidURL

    var userFacingMessage: String {
        switch self {
        case .emptyURL:
            return "URL is missing address."
        case .unsupportedScheme:
            return "URL must start with http:// or https://."
        case .missingHost:
            return "URL is missing a valid domain."
        case .invalidURL:
            return "URL is not valid."
        }
    }
}

enum URLNormalizer {
    static func normalizedURL(from rawValue: String) throws -> URL {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty, trimmed != "https://", trimmed != "http://" else {
            throw URLNormalizationError.emptyURL
        }

        let valueWithScheme = hasExplicitScheme(trimmed) ? trimmed : "https://\(trimmed)"

        guard
            let components = URLComponents(string: valueWithScheme),
            let scheme = components.scheme?.lowercased(),
            let host = components.host,
            !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw URLNormalizationError.missingHost
        }

        guard scheme == "http" || scheme == "https" else {
            throw URLNormalizationError.unsupportedScheme(scheme)
        }

        guard let url = components.url else {
            throw URLNormalizationError.invalidURL
        }

        return url
    }

    static func displayTitle(for rawValue: String) -> String {
        if let url = try? normalizedURL(from: rawValue), let host = url.host, !host.isEmpty {
            return host
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "URL" : trimmed
    }

    private static func hasExplicitScheme(_ value: String) -> Bool {
        guard let schemeDelimiterRange = value.range(of: "://") else {
            return false
        }

        return !value[..<schemeDelimiterRange.lowerBound].isEmpty
    }
}
