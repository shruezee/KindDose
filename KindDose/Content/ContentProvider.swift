//
//  ContentProvider.swift
//  KindDose
//

import Foundation

struct Joke: Codable, Identifiable, Hashable {
    let id: String
    let setup: String
    let punchline: String
}

struct ValidationTemplate: Codable, Identifiable, Hashable {
    let id: String
    let text: String
}

/// Hands out jokes and validation messages from the bundled content.
/// Each set is shuffled and drawn from in order, never repeating an item
/// until every item in that set has been shown once.
final class ContentProvider {
    static let shared = ContentProvider()

    let jokes: [Joke]
    let validations: [ValidationTemplate]
    let missedValidations: [ValidationTemplate]

    private var jokeDeck: [Joke] = []
    private var validationDeck: [ValidationTemplate] = []
    private var missedValidationDeck: [ValidationTemplate] = []

    private init() {
        jokes = Bundle.main.decodeJSON("Jokes") ?? []
        validations = Bundle.main.decodeJSON("Validations") ?? []
        missedValidations = Bundle.main.decodeJSON("MissedValidations") ?? []
        jokeDeck = jokes.shuffled()
        validationDeck = validations.shuffled()
        missedValidationDeck = missedValidations.shuffled()
    }

    func nextJoke() -> Joke? {
        if jokeDeck.isEmpty { jokeDeck = jokes.shuffled() }
        return jokeDeck.popLast()
    }

    func nextValidation() -> ValidationTemplate? {
        if validationDeck.isEmpty { validationDeck = validations.shuffled() }
        return validationDeck.popLast()
    }

    func nextMissedValidation() -> ValidationTemplate? {
        if missedValidationDeck.isEmpty { missedValidationDeck = missedValidations.shuffled() }
        return missedValidationDeck.popLast()
    }

    /// A stable pick for the whole day — the same joke all day, a different one the next day.
    func jokeOfTheDay(for date: Date = Date()) -> Joke? {
        guard !jokes.isEmpty else { return nil }
        let dayNumber = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return jokes[dayNumber % jokes.count]
    }
}

private extension Bundle {
    func decodeJSON<T: Decodable>(_ name: String, withExtension ext: String = "json") -> T? {
        guard let url = url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
