//
//  LessonViewModel.swift
//  rSoGuitar
//
//  ViewModel for lesson management
//

import Foundation
import SwiftUI
import Combine

class LessonViewModel: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var selectedLesson: Lesson?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let contentService = ContentService.shared
    private let progressService = ProgressService.shared
    private let subscriptionService = SubscriptionService.shared
    
    init() {
        loadLessons()
    }
    
    func loadLessons() {
        isLoading = true
        lessons = contentService.getAllLessons().sorted { $0.order < $1.order }
        isLoading = false
    }
    
    func selectLesson(_ lesson: Lesson) {
        // Check premium access
        if lesson.isPremium && !subscriptionService.isPremiumUser {
            // Premium gate will be handled by the view
            return
        }
        
        selectedLesson = lesson
        progressService.updateCurrentLesson(lesson.id)
    }
    
    func completeLesson(_ lessonId: UUID) {
        progressService.markLessonCompleted(lessonId)
    }
    
    func canAccessLesson(_ lesson: Lesson) -> Bool {
        if !lesson.isPremium {
            return true
        }
        return subscriptionService.isPremiumUser
    }
    
    func getFreeLessons() -> [Lesson] {
        return lessons.filter { !$0.isPremium }
    }
    
    func getPremiumLessons() -> [Lesson] {
        return lessons.filter { $0.isPremium }
    }
    
    func isLessonCompleted(_ lessonId: UUID) -> Bool {
        progressService.isLessonCompleted(lessonId)
    }
}

