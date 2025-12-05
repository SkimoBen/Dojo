//
//  ChatView.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-11-22.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @StateObject var chatVM: ChatViewModel = ChatViewModel()
    @EnvironmentObject var dojo: DojoViewModel
    @Environment(\.modelContext) var modelContext
    
    @State private var inputText: String = ""
    @State private var isAtBottom: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesList
                Spacer()
                MyChatComposer(text: $inputText, isSending: dojo.isSending) {
                    Task { await send() }
                }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(.clear)
            }
            .background(papaya_50)
            .navigationTitle("Coach Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Messages
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(chatVM.messages.enumerated()), id: \.offset) { index, msg in
                        messageRow(for: msg)
                            .id(index)
                            .padding(.horizontal, 16)
                            .padding(.top, index == 0 ? 12 : 0)
                    }
                    Color.clear.frame(height: 1).id("BOTTOM")
                }
                .padding(.vertical, 8)
            }
            .background(papaya_50)
            .onChange(of: chatVM.messages.count) {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                proxy.scrollTo("BOTTOM", anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private func messageRow(for message: ChatViewModel.ChatMessage) -> some View {
        switch message {
        case .user(let user):
            HStack {
                Spacer(minLength: 40)
                VStack(alignment: .leading, spacing: 6) {
                    Text("You")
                        .font(.zenCaption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 6)
                    Text(user.content)
                        .font(.zenBody)
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(vermillion)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ash.opacity(0.4), lineWidth: 0.5)
                        )
                        .textSelection(.enabled)

                }
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))

        case .assistant(let assistant):
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(jet)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text("AI")
                            .font(.zenCaption2)
                            .foregroundStyle(.white)
                    )
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Coach")
                        .font(.zenCaption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)

                    Text(assistantText(assistant))
                        .font(.zenBody)
                        .foregroundStyle(jet)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ash, lineWidth: 1)
                        )
                        .sunkenPanel(cornerRadius: 14, fill: Color(.systemGray6))
                        .textSelection(.enabled)

                }
                Spacer(minLength: 40)
            }
            .transition(.move(edge: .leading).combined(with: .opacity))

        default:
            EmptyView() // Ignore other message types for now
        }
    }

    private func assistantText(_ msg: ChatViewModel.AssistantMessage) -> String {
        // Concatenate the assistant content text blocks
        msg.content.map { $0.text }.joined(separator: "\n\n")
    }

    // MARK: - Input Bar
//    private var inputBar: some View {
//        ChatComposer(
//            text: $inputText,
//            isSending: dojo.isSending,
//            placeholder: "Tell the coach about your session, goals, or ask a question..."
//        ) {
//            Task { await send() }
//        }
        
//    }

    // MARK: - Actions
    private func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        
        // Update the chat model
        chatVM.appendUserMessageToChatMessages(newMsg: trimmed)
        inputText = ""
        chatVM.updateCoordinatorContextFromViewModel(
            goals: dojo.userDefinedGoals,
            fitness: dojo.activityFitnessLevel,
            workoutPlans: dojo.dailyWorkoutPlans
        )
        
        let dataOrNil = await chatVM.sendChatPayload()
        guard let data = dataOrNil else { return } // TODO: Show an alert here
        
        let (chatResponseOrNil, errorOrNil) = chatVM.createChatResponseFromData(data)
        
        if errorOrNil != nil {
            // TODO: Show an alert here
        }
        guard let chatResponse = chatResponseOrNil else { return }
        
        // Update the Dojo View Model with new context
        dojo.updateDojoViewModelFromChatResponse(chatResponse)
        withAnimation {
            chatVM.messages = chatResponse.messages
        }
        
        // Persist the update in SwiftData storage
        dojo.persistFreshContext(modelContext: modelContext)
        print("✉️ Chat Messages \n")
    }
}

struct MyChatComposer: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField(
                "Tell the coach about your session, goals, or ask a question...",
                text: $text,
                axis: .vertical  // 👈 this makes it grow vertically
            )
            .lineLimit(1...4)    // 👈 starts at 1 line, grows up to 4
            .textFieldStyle(.roundedBorder)
            .padding(.vertical, 8)

            Button(action: {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, isSending == false else { return }
                onSend()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [raspberry, vermillion],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: isSending ? "hourglass" : "paperplane.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: 36, height: 36)
            }
            .padding(.leading, 4)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? 0.6 : 1.0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}


// MARK: - Inline Chat Composer (SwiftUI-only, auto-expands to 100pt then scrolls)
private struct ChatComposer: View {
    @Binding var text: String
    var isSending: Bool = false
    var placeholder: String
    var onSend: () -> Void
    
    // Layout constants
    private let cornerRadius: CGFloat = 12
    private let horizontalPadding: CGFloat = 10
    private let verticalPadding: CGFloat = 8
    private let sendButtonSize: CGFloat = 36
    private let sendButtonPadding: CGFloat = 8
    private let maxEditorHeight: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background + border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(ash, lineWidth: 1)
                )
            
            // Auto-growing text editor: starts 1 line, grows up to ~100pt, then scrolls
           TextEditor(text: $text)
                .frame(minHeight: 20, maxHeight: 100)
            .padding(.leading, horizontalPadding)
            .padding(.trailing, horizontalPadding + sendButtonSize + 6) // leave room for send button
            .padding(.vertical, verticalPadding)
            
            // Send button
            Button(action: {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, isSending == false else { return }
                onSend()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [raspberry, vermillion],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: isSending ? "hourglass" : "paperplane.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: sendButtonSize, height: sendButtonSize)
            }
            .padding(sendButtonPadding)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? 0.6 : 1.0)
            .accessibilityLabel("Send message")
        }
    }
}



#Preview {
    ChatView()
        .environmentObject(DojoViewModel())
}
