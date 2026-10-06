//
//  MedicineTextParsing.swift
//  KindDose
//

import Foundation

/// Best-guess extraction of a dose and schedule from recognized or spoken text,
/// e.g. "Metformin 500 milligrams morning and night." These are only starting
/// points — the person always reviews and can correct them on the confirm screen.
enum MedicineTextParsing {
    private static let doseRegex = try! NSRegularExpression(
        pattern: #"\d+(\.\d+)?\s?(mg|mcg|g|ml|milligrams?|micrograms?|milliliters?|millilitres?|units?)\b"#,
        options: [.caseInsensitive]
    )

    static func guessDose(in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = doseRegex.firstMatch(in: text, range: range),
              let swiftRange = Range(match.range, in: text)
        else { return nil }
        return String(text[swiftRange])
    }

    static func guessTimes(in text: String) -> [DateComponents] {
        let lower = text.lowercased()
        func time(_ hour: Int, _ minute: Int = 0) -> DateComponents {
            DateComponents(hour: hour, minute: minute)
        }

        if lower.contains("three times") || lower.contains("thrice") || lower.contains("3 times") {
            return [time(8), time(14), time(20)]
        }
        if lower.contains("twice") || lower.contains("two times") || lower.contains("2 times")
            || (lower.contains("morning") && (lower.contains("night") || lower.contains("evening"))) {
            return [time(8), time(20)]
        }
        if lower.contains("bedtime") {
            return [time(22)]
        }
        if lower.contains("night") || lower.contains("evening") {
            return [time(20)]
        }
        if lower.contains("afternoon") || lower.contains("midday") || lower.contains("noon") {
            return [time(13)]
        }
        if lower.contains("morning") || lower.contains("once") || lower.contains("daily") {
            return [time(8)]
        }
        return []
    }

    /// Picks the first non-empty line that isn't the dose itself as a name guess.
    static func guessName(from lines: [String], excluding dose: String?) -> String {
        for line in lines {
            var candidate = line
            if let dose, let range = candidate.range(of: dose, options: .caseInsensitive) {
                candidate.removeSubrange(range)
            }
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 2 {
                return trimmed
            }
        }
        return ""
    }
}
