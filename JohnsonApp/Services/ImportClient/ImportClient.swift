//
//  ImportClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Foundation

struct ImportClient {
    var parse: @Sendable (String) -> ImportResult
}

extension ImportClient: DependencyKey {
    static let liveValue = Self(
        parse: { text in
            var validTerms: [ParsedTerm] = []
            var invalidLines: [InvalidLine] = []
            var lineNumber = 0

            for line in text.components(separatedBy: .newlines) {
                lineNumber += 1
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                guard !trimmed.isEmpty else { continue }

                if let parsed = Self.parseLine(trimmed) {
                    validTerms.append(parsed)
                } else {
                    invalidLines.append(InvalidLine(lineNumber: lineNumber, content: trimmed))
                }
            }

            return ImportResult(validTerms: validTerms, invalidLines: invalidLines)
        }
    )

    static let testValue = Self(
        parse: { _ in ImportResult(validTerms: [], invalidLines: []) }
    )

    // MARK: - Parsing

    /// Parses a single non-empty trimmed line into a ParsedTerm.
    /// Returns nil if the line does not match the required format.
    ///
    /// Requires a dash separator surrounded by whitespace on both sides.
    /// Supported dash variants:
    ///   - Short hyphen (-)
    ///   - En dash (–)
    ///   - Em dash (—)
    ///   - Other Unicode dashes (‒, ―, ﹣, －)
    ///
    /// Supported formats:
    ///   term - translation
    ///   term — translation (hint)
    ///   term – translation
    private nonisolated static func parseLine(_ line: String) -> ParsedTerm? {
        guard let separatorRange = findSeparatorRange(in: line) else { return nil }

        let termText = String(line[line.startIndex..<separatorRange.lowerBound])
            .trimmingCharacters(in: .whitespaces)
        let rest = String(line[separatorRange.upperBound...])
            .trimmingCharacters(in: .whitespaces)

        guard !termText.isEmpty, !rest.isEmpty else { return nil }

        var translation = rest
        var hint: String? = nil

        if rest.hasSuffix(")"), let openParen = rest.lastIndex(of: "(") {
            let hintContent = String(rest[rest.index(after: openParen)..<rest.index(before: rest.endIndex)])
                .trimmingCharacters(in: .whitespaces)
            let translationPart = String(rest[rest.startIndex..<openParen])
                .trimmingCharacters(in: .whitespaces)

            if !translationPart.isEmpty, !hintContent.isEmpty {
                translation = translationPart
                hint = hintContent
            }
        }

        guard !translation.isEmpty else { return nil }

        return ParsedTerm(termText: termText, translation: translation, hint: hint)
    }

    private nonisolated static func findSeparatorRange(in line: String) -> Range<String.Index>? {
        let regex = #"\s+[-\u{2013}\u{2014}\u{2012}\u{2015}\u{FE63}\u{FF0D}]\s+"#
        return line.range(of: regex, options: .regularExpression)
    }
}

extension DependencyValues {
    var importClient: ImportClient {
        get { self[ImportClient.self] }
        set { self[ImportClient.self] = newValue }
    }
}
