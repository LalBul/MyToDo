//
//  TaskViewModel.swift
//  MyToDo
//
//  Created by Владимир Сербин on 27.05.2025.
//


import Foundation
import UserNotifications

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []

    private let storageKey = "myToDoTasks"

    init() {
        loadTasks()
        
        // Запрос на разрешение отправлять уведомления
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Ошибка при запросе уведомлений: \(error.localizedDescription)")
            } else {
                print("Разрешение на уведомления: \(granted)")
            }
        }
    }
    
    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        saveTasks()
    }

    func addTask(title: String, dueDate: Date? = nil, shouldRemind: Bool = false, reminderDate: Date? = nil, colorTag: String? = nil) {
        let newTask = Task(
            title: title,
            isCompleted: false,
            dueDate: dueDate,
            shouldRemind: shouldRemind,
            reminderDate: reminderDate,
            colorTag: colorTag
        )
        tasks.append(newTask)
        saveTasks()

        if shouldRemind, let reminderDate = reminderDate {
            scheduleNotification(for: newTask)
        }
    }
    
    func updateTaskTitle(id: UUID, newTitle: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].title = newTitle
            saveTasks()
        }
    }
    
    func movePinnedTask(from source: IndexSet, to destination: Int) {
        let pinned = tasks.enumerated().filter { $0.element.isPinned }
        var newPinnedTasks = pinned.map { $0.element }

        newPinnedTasks.move(fromOffsets: source, toOffset: destination)

        // Теперь нужно обновить порядок в общем списке
        var updatedTasks: [Task] = []
        var pinnedIndex = 0

        for task in tasks {
            if task.isPinned {
                updatedTasks.append(newPinnedTasks[pinnedIndex])
                pinnedIndex += 1
            } else {
                updatedTasks.append(task)
            }
        }

        tasks = updatedTasks
        saveTasks()
    }
    
    func deleteTasks(_ tasks: [Task]) {
        for task in tasks {
            if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                self.tasks.remove(at: index)
            }
        }
        saveTasks()
    }
    
    func moveTaskWithinGroup(from source: IndexSet, to destination: Int, pinned: Bool) {
        let group = tasks.enumerated().filter { $0.element.isPinned == pinned }

        let sourceOffsets = source.map { group[$0].offset }
        let adjustedDestination = group.indices.contains(destination) ? group[destination].offset : tasks.endIndex

        for index in sourceOffsets.sorted(by: >) {
            let moved = tasks.remove(at: index)
            tasks.insert(moved, at: adjustedDestination > index ? adjustedDestination - 1 : adjustedDestination)
        }

        saveTasks()
    }
    
    func moveUnpinnedTask(from source: IndexSet, to destination: Int) {
        let unpinned = tasks.enumerated().filter { !$0.element.isPinned }
        var mutableTasks = tasks

        let sourceIndices = source.map { unpinned[$0].offset }
        let destinationIndex = destination < unpinned.count ? unpinned[destination].offset : tasks.endIndex

        let moving = sourceIndices.map { mutableTasks.remove(at: $0) }

        let insertionIndex = destinationIndex - sourceIndices.filter { $0 < destinationIndex }.count
        mutableTasks.insert(contentsOf: moving, at: insertionIndex)

        tasks = mutableTasks
        saveTasks()
    }
    
    func scheduleNotification(for task: Task) {
        guard let reminderDate = task.reminderDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Напоминание"
        content.body = task.title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка при создании уведомления: \(error.localizedDescription)")
            } else {
                print("✅ Уведомление запланировано для задачи: \(task.title)")
            }
        }
    }

    func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let task = tasks[index]
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
        }
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }

    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    func togglePin(for task: Task) {
        if let index = tasks.firstIndex(of: task) {
            tasks[index].isPinned.toggle()
            saveTasks()
        }
    }

    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded.sorted { $0.isPinned && !$1.isPinned }
            print(tasks)
        }
    }
}
