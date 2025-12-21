//
//  ProgressService.swift
//  rSoGuitar
//
//  Manages user progress tracking
//

import Foundation
import SwiftData
import Combine

class ProgressService: ObservableObject {
    static let shared = ProgressService()
    
    private var modelContext: ModelContext?
    @Published var userProgress: UserProgress?
    
    private init() {
        // Progress will be loaded when model context is set
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadProgress()
    }
    
    func loadProgress() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserProgress>()
        if let progress = try? modelContext.fetch(descriptor).first {
            userProgress = progress
        } else {
            // Create new progress
            let progress = UserProgress()
            modelContext.insert(progress)
            userProgress = progress
            try? modelContext.save()
        }
    }
    
    func markLessonCompleted(_ lessonId: UUID) {
        guard let progress = userProgress else { return }
        progress.markLessonCompleted(lessonId)
        saveProgress()
    }
    
    func toggleBookmark(_ patternId: UUID) {
        guard let progress = userProgress else { return }
        progress.toggleBookmark(patternId)
        saveProgress()
    }
    
    func updateCurrentLesson(_ lessonId: UUID?) {
        guard let progress = userProgress else { return }
        progress.currentLessonId = lessonId
        progress.lastAccessedDate = Date()
        saveProgress()
    }
    
    func addPracticeTime(_ time: TimeInterval) {
        guard let progress = userProgress else { return }
        progress.totalPracticeTime += time
        saveProgress()
    }
    
    func isLessonCompleted(_ lessonId: UUID) -> Bool {
        userProgress?.isCompleted(lessonId) ?? false
    }
    
    func isPatternBookmarked(_ patternId: UUID) -> Bool {
        userProgress?.isBookmarked(patternId) ?? false
    }
    
    private func saveProgress() {
        guard let modelContext = modelContext else { return }
        try? modelContext.save()
    }
}

