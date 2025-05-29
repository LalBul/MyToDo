//
//  AddTaskView.swift
//  MyToDo
//
//  Created by Владимир Сербин on 27.05.2025.
//

import SwiftUI

struct AddTaskView: View {
    
    @ObservedObject var viewModel: TaskViewModel
    var onCancel: () -> Void

    @State private var taskText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var taskDate = Date()
    @State private var hasDate = false
    @State private var shake = false
    
    @State private var shouldRemind = false
    @State private var reminderDate = Date()
    
    let colorOptions: [(name: String, color: Color)] = [
        ("red", .red),
        ("blue", .blue),
        ("green", .green),
        ("orange", .orange),
        ("purple", .purple)
    ]

    @State private var selectedColorName: String? = nil
    

    var body: some View {
        ZStack {
            // Затемнение и размытие фона
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .background(Color.black.opacity(0.3))
                .onTapGesture {
                    onCancel()
                }

            // Главное окно
            VStack(spacing: 20) {
                Text("Новая задача")
                    .font(.title3)
                    .bold()
                
                Toggle("Указать дату", isOn: $hasDate)
                    .padding(.horizontal)

                if hasDate {
                    DatePicker("Дата", selection: $taskDate, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal)
                }
                
                Toggle("Хочу напоминание", isOn: $shouldRemind)
                    .padding(.horizontal)

                if shouldRemind {
                    DatePicker("Когда напомнить", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal)
                }

                TextField("Введите текст задачи", text: $taskText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                    .modifier(ShakeEffect(shakes: shake ? 2 : 0)) // Тряска

                HStack {
                    Button("Отмена") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)

                    Spacer()

                    Button("Добавить") {
                        let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            shake = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                shake = false
                            }
                            return
                        }
                        viewModel.addTask(
                            title: trimmed,
                            dueDate: hasDate ? taskDate : nil,
                            shouldRemind: shouldRemind,
                            reminderDate: shouldRemind ? reminderDate : nil,
                            colorTag: selectedColorName
                        )
                        onCancel()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.black)
                    .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        ForEach(colorOptions, id: \.name) { option in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: selectedColorName == option.name ? 32 : 24,
                                           height: selectedColorName == option.name ? 32 : 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(selectedColorName == option.name ? 0.8 : 0.3), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedColorName = option.name
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
        .animation(.easeInOut(duration: 0.3), value: shake)
    }
}

#Preview {
    AddTaskView(viewModel: TaskViewModel()) {
        print("Cancel tapped")
    }
}
