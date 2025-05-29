//
//  ContentView.swift
//  MyToDo
//
//  Created by Владимир Сербин on 27.05.2025.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = TaskViewModel()

    @State private var showingAddTask = false
    @State private var showModalContent = false
    @State private var searchText = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var editingTaskID: UUID?
    @State private var editedTitle: String = ""
    @FocusState private var isEditingFocused: Bool

    enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "Все"
        case active = "Активные"
        case completed = "Выполненные"
        case withReminders = "С напоминанием"

        var id: String { rawValue }
    }

    func colorFrom(tag: String) -> Color {
        switch tag {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .gray
        }
    }

    func icon(for filter: TaskFilter) -> String {
        switch filter {
        case .all: return "tray.full"
        case .active: return "circle"
        case .completed: return "checkmark.circle"
        case .withReminders: return "bell"
        }
    }

    var filteredTasks: [Task] {
        let baseTasks: [Task]
        switch selectedFilter {
        case .all: baseTasks = viewModel.tasks
        case .active: baseTasks = viewModel.tasks.filter { !$0.isCompleted }
        case .completed: baseTasks = viewModel.tasks.filter { $0.isCompleted }
        case .withReminders: baseTasks = viewModel.tasks.filter { $0.shouldRemind }
        }
        return searchText.isEmpty ? baseTasks : baseTasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var pinnedTasks: [Task] { filteredTasks.filter { $0.isPinned } }
    var unpinnedTasks: [Task] { filteredTasks.filter { !$0.isPinned } }

    func saveEdit(for task: Task) {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.updateTaskTitle(id: task.id, newTitle: trimmed)
        withAnimation { editingTaskID = nil }
    }

    func deleteUnpinned(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { unpinnedTasks[$0] }
        viewModel.deleteTasks(tasksToDelete)
    }

    func taskRow(_ task: Task) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { viewModel.toggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .imageScale(.large)
            }
            VStack(alignment: .leading, spacing: 4) {
                if editingTaskID == task.id {
                    TextField("Название задачи", text: $editedTitle)
                        .padding(8)
                        .background(Color(.white))
                        .cornerRadius(8)
                        .font(.body)
                        .focused($isEditingFocused)
                        .onSubmit { saveEdit(for: task) }
                        .onChange(of: isEditingFocused) { if !$0 { saveEdit(for: task) } }
                } else {
                    HStack(spacing: 4) {
                        Text(task.title)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .gray : .primary)
                            .font(.body)
                            .onTapGesture {
                                withAnimation {
                                    editingTaskID = task.id
                                    editedTitle = task.title
                                    isEditingFocused = true
                                }
                            }
                        if task.isPinned {
                            Image(systemName: "pin.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
                if let due = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").foregroundColor(.gray)
                        Text(due.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.gray)
                    }
                }
                if let tag = task.colorTag {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill").foregroundColor(colorFrom(tag: tag)).font(.caption)
                        Text(tag.capitalized).font(.caption).foregroundColor(colorFrom(tag: tag))
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(colorFrom(tag: tag).opacity(0.1))
                    .cornerRadius(8)
                }
                if task.shouldRemind, let reminderDate = task.reminderDate {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill").foregroundColor(.orange).font(.caption)
                        Text("Напоминание: \(reminderDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1)).cornerRadius(8)
                }
            }
        }
        .padding(8)
        .contextMenu {
            Button { viewModel.togglePin(for: task) } label: {
                Label(task.isPinned ? "Открепить" : "Закрепить", systemImage: "pin")
            }
        }
    }

    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    if !viewModel.tasks.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("Поиск задач", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle()).disableAutocorrection(true)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10).background(Color(.systemBackground)).cornerRadius(10)
                        .padding([.horizontal, .top])
                    }
                    if filteredTasks.isEmpty {
                        Spacer()
                        Text("Задач пока нет").foregroundColor(.gray).font(.headline)
                        Spacer()
                    } else {
                        List {
                            if !pinnedTasks.isEmpty {
                                Section {
                                    ForEach(pinnedTasks) { task in taskRow(task) }
                                    .onMove { indices, newOffset in
                                        viewModel.moveTaskWithinGroup(from: indices, to: newOffset, pinned: true)
                                    }
                                }
                            }
                            if !unpinnedTasks.isEmpty {
                                Section {
                                    ForEach(unpinnedTasks) { task in taskRow(task) }
                                    .onDelete(perform: deleteUnpinned)
                                    .onMove { indices, newOffset in
                                        viewModel.moveTaskWithinGroup(from: indices, to: newOffset, pinned: false)
                                    }
                                }
                            }
                        }.listStyle(InsetGroupedListStyle())
                    }
                }
                .navigationTitle("MyToDo")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Menu {
                                ForEach(TaskFilter.allCases) { filter in
                                    Button { selectedFilter = filter } label: {
                                        HStack {
                                            Image(systemName: icon(for: filter))
                                            Text(filter.rawValue)
                                            if selectedFilter == filter {
                                                Spacer()
                                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: icon(for: selectedFilter)).foregroundColor(.black).imageScale(.large)
                            }
                            Button { withAnimation { showingAddTask = true } } label: {
                                Image(systemName: "plus").imageScale(.large).foregroundColor(.black)
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton().foregroundColor(.black)
                    }
                }
            }
            if showingAddTask {
                ZStack {
                    if showModalContent {
                        Color.black.opacity(0.4).ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation { showModalContent = false }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showingAddTask = false
                                }
                            }
                        AddTaskView(viewModel: viewModel) {
                            withAnimation { showModalContent = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingAddTask = false
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity)).zIndex(1)
                    }
                }
                .onAppear { showModalContent = true }
                .animation(.easeInOut(duration: 0.3), value: showModalContent)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingAddTask)
    }
}

#Preview {
    ContentView()
}
