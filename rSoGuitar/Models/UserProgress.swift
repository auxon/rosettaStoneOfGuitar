//
//  UserProgress.swift
//  rSoGuitar
//
//  User progress tracking model
//

import Foundation
import SwiftData

@Model
final class UserProgress {
    var completedLessons: [UUID]
    var bookmarkedPatterns: [UUID]
    var currentLessonId: UUID?
    var lastAccessedDate: Date
    var totalPracticeTime: TimeInterval
    
    init(
        completedLessons: [UUID] = [],
        bookmarkedPatterns: [UUID] = [],
        currentLessonId: UUID? = nil,
        lastAccessedDate: Date = Date(),
        totalPracticeTime: TimeInterval = 0
    ) {
        self.completedLessons = completedLessons
        self.bookmarkedPatterns = bookmarkedPatterns
        self.currentLessonId = currentLessonId
        self.lastAccessedDate = lastAccessedDate
        self.totalPracticeTime = totalPracticeTime
    }
    
    func markLessonCompleted(_ lessonId: UUID) {
        if !completedLessons.contains(lessonId) {
            completedLessons.append(lessonId)
        }
    }
    
    func toggleBookmark(_ patternId: UUID) {
        if let index = bookmarkedPatterns.firstIndex(of: patternId) {
            bookmarkedPatterns.remove(at: index)
        } else {
            bookmarkedPatterns.append(patternId)
        }
    }
    
    func isBookmarked(_ patternId: UUID) -> Bool {
        bookmarkedPatterns.contains(patternId)
    }
    
    func isCompleted(_ lessonId: UUID) -> Bool {
        completedLessons.contains(lessonId)
    }
}

