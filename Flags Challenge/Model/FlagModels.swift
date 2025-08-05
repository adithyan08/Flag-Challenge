import SwiftUI
import CoreData



struct ApiResponse: Codable {
    let questions: [ApiQuestion]
}

struct ApiQuestion: Codable, Identifiable {
    let answer_id: Int
    let countries: [ApiCountry]
    let country_code: String

    var id: Int { answer_id }
}

struct ApiCountry: Codable {
    let country_name: String
    let id: Int
}

struct QuizQuestion{
    let id: Int
    let flagImageName: String
    let options: [String]
    let correctOptionIndex: Int
}

// MARK: - Core Data extensions

extension QuestionEntity {
    func toQuizQuestion() -> QuizQuestion {
        let opts = (options as? [String]) ?? []
        return QuizQuestion(id: Int(id),
                            flagImageName: flagName ?? "",
                            options: opts,
                            correctOptionIndex: Int(correctIndex))
    }
}

extension QuizQuestion {
    func toEntity(in context: NSManagedObjectContext) -> QuestionEntity {
        let entity = QuestionEntity(context: context)
        entity.id = Int64(id)
        entity.flagName = flagImageName
        entity.options = options as NSArray
        entity.correctIndex = Int16(correctOptionIndex)
        return entity
    }
}
