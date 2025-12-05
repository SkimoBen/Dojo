//
//  LocalAgentChat.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-11-20.
//

import SwiftUI
import FoundationModels

struct LocalAgentChat: View {
    let rc = RunningCoach()
    @State var coachResponse: String.PartiallyGenerated?
    @State var userMesssage: String = ""
    @State var isGenerating: Bool = false
    var body: some View {
        ScrollView {
            VStack {
                
                if let cr = coachResponse {
                    Text(cr)
                        .padding()
                        .background(.cyan.opacity(0.2))
                }
                Spacer()
                HStack {
                    
                    TextField("-> ", text: $userMesssage)
                        .frame(minHeight: 50, maxHeight: 75)
                        .background(.black.opacity(0.05))
                        .padding()
                        .cornerRadius(12.0)
                        .onSubmit {
                            Task {
                                do {
                                    let stream = rc.session.streamResponse(to: userMesssage)
                                    for try await partial in stream {
                                        coachResponse = partial.content
                                        
                                    }
                              
                                } catch {
                                    
                                }
                            }
                        }
                
                    Button(action: {
                        
                    }, label: {
                        Image("paperplane")
                    })
                }
                
            }
        }
        
    }
}

#Preview {
    LocalAgentChat()
}
