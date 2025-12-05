//
//  TestChatView.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-23.
//

import SwiftUI

struct ChatTestView: View {
    // UI state
    @State private var input: String = ""
    @State private var transcript: String = ""
    @State private var isStreaming: Bool = false
    @State private var errorText: String = ""

    // Change this to your Mac's LAN IP if testing on a physical device.
    // private let endpoint = URL(string: "http://127.0.0.1:8000/chat")!
    private let endpoint = URL(string: "http://10.13.139.201:8000/chat")!
    

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if transcript.isEmpty {
                        Text("Response will appear here…")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(transcript)
                    }
                    if !errorText.isEmpty {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                TextField("Say something…", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isStreaming)

                Button(isStreaming ? "Streaming…" : "Send") {
                    Task { await send() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(input.isEmpty || isStreaming)
            }
        }
        .padding()
    }

    // MARK: - Networking

    private func makeRequest(body: [String: Any]) throws -> URLRequest {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Your FastAPI currently returns `text/plain` for the stream; accept that.
        req.setValue("text/plain", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    private func parseSSELine(_ line: String) {
        // Expect lines like:  data: {"content":"..."}
        guard line.hasPrefix("data: ") else { return }
        let jsonString = String(line.dropFirst(6))
        guard let data = jsonString.data(using: .utf8),
              let any = try? JSONSerialization.jsonObject(with: data),
              let dict = any as? [String: Any],
              let piece = dict["content"] as? String else { return }

        transcript += piece
    }

    private func resetForNewRequest() {
        transcript = ""
        errorText = ""
    }

    private func buildBody(for text: String) -> [String: Any] {
        [
            "messages": [
                ["role": "user", "content": text]
            ],
            "userId": "ios-test"
        ]
    }

    // Streams the response line-by-line and updates `transcript`.
    private func stream(body: [String: Any]) async throws {
        let request = try makeRequest(body: body)
        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "ChatTestView", code: status, userInfo: [NSLocalizedDescriptionKey: "HTTP \(status)"])
        }

        for try await line in bytes.lines {
            // FastAPI yields blank lines between events; safe to skip empty ones.
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            parseSSELine(line)
        }
    }

    // Public send action
    private func send() async {
        guard !input.isEmpty else { return }
        resetForNewRequest()
        isStreaming = true
        let body = buildBody(for: input)
        defer { isStreaming = false }

        do {
            try await stream(body: body)
        } catch {
            errorText = error.localizedDescription
        }
    }
}
