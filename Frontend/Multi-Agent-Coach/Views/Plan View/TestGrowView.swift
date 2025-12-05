//
//  TestGrowView.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-10-08.
//

import SwiftUI

struct GlassViewTesting: View {
    @State private var dragOffset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle().fill(.blue)
                Rectangle().fill(.red)
                Rectangle().fill(.green)
            }
            
            if #available(iOS 26.0, *) { // 26.0 doesn’t exist yet — probably meant 16.0
                GlassEffectContainer {
                    VStack(spacing: 16) {
                        // Draggable rectangle
                        VStack{
                            Text("Top")
                        }
                        .frame(width: 160, height: 120)
                        .glassEffect(.clear)
                        //.foregroundStyle(.clear)
                        // Combine both offsets manually
                        .offset(
                            x: dragOffset.width + dragTranslation.width,
                            y: dragOffset.height + dragTranslation.height
                        )
                        .gesture(
                            DragGesture()
                                .updating($dragTranslation) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    dragOffset.width += value.translation.width
                                    dragOffset.height += value.translation.height
                                }
                        )
                        .animation(.interactiveSpring(), value: dragOffset)
                        
                        VStack{
                            Text("Bottom")
                        }
                        .glassEffect(.clear)
                        .frame(width: 160, height: 120)
                        
                    }
                    .padding()
                }
            } else {
                VStack {
                    Text("Dead")
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct GradientTest: View {
    let gradient = AngularGradient(colors: [ash, vermillion], center: .center, angle: .degrees(180))
    let radGrad = RadialGradient(colors: [ash, ash, vermillion], center: .bottomLeading, startRadius: 0.0, endRadius: 400.0)
    var body: some View {
        Circle()
            .fill(gradient)
        Rectangle()
            .fill(.white)
            .overlay(content: {
                
            })
    }
}

#Preview {
    GradientTest()
}


