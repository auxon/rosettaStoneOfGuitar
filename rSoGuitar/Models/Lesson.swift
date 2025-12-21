//
//  Lesson.swift
//  rSoGuitar
//
//  Lesson model and content types
//

import Foundation

struct Lesson: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let content: [LessonContent]
    let isPremium: Bool
    let order: Int
    let estimatedTime: TimeInterval
    
    init(id: UUID = UUID(), title: String, description: String, content: [LessonContent], isPremium: Bool, order: Int, estimatedTime: TimeInterval) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.isPremium = isPremium
        self.order = order
        self.estimatedTime = estimatedTime
    }
}

enum LessonContent: Codable {
    case text(String)
    case fretboardDemo(Pattern)
    case audioExample(String) // URL as string
    case exercise(Exercise)
    
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    enum ContentType: String, Codable {
        case text, fretboardDemo, audioExample, exercise
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .text:
            let value = try container.decode(String.self, forKey: .value)
            self = .text(value)
        case .fretboardDemo:
            let value = try container.decode(Pattern.self, forKey: .value)
            self = .fretboardDemo(value)
        case .audioExample:
            let value = try container.decode(String.self, forKey: .value)
            self = .audioExample(value)
        case .exercise:
            let value = try container.decode(Exercise.self, forKey: .value)
            self = .exercise(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let value):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(value, forKey: .value)
        case .fretboardDemo(let value):
            try container.encode(ContentType.fretboardDemo, forKey: .type)
            try container.encode(value, forKey: .value)
        case .audioExample(let value):
            try container.encode(ContentType.audioExample, forKey: .type)
            try container.encode(value, forKey: .value)
        case .exercise(let value):
            try container.encode(ContentType.exercise, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

struct Exercise: Codable {
    let id: UUID
    let title: String
    let instructions: String
    let pattern: Pattern?
    let correctAnswers: [FretboardPosition]
    
    init(id: UUID = UUID(), title: String, instructions: String, pattern: Pattern? = nil, correctAnswers: [FretboardPosition] = []) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.pattern = pattern
        self.correctAnswers = correctAnswers
    }
}

