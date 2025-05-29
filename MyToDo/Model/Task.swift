//
//  Task.swift
//  MyToDo
//
//  Created by Владимир Сербин on 27.05.2025.
//

import Foundation

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var shouldRemind: Bool
    var reminderDate: Date?
    var colorTag: String?
    var isPinned: Bool // ✅ новое поле

    init(id: UUID = UUID(),
         title: String,
         isCompleted: Bool = false,
         dueDate: Date? = nil,
         shouldRemind: Bool = false,
         reminderDate: Date? = nil,
         colorTag: String? = nil,
         isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.shouldRemind = shouldRemind
        self.reminderDate = reminderDate
        self.colorTag = colorTag
        self.isPinned = isPinned
    }
}
