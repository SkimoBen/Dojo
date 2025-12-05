//
//  ViewComponents.swift
//  Multi-Agent-Coach
//
//  Created by iLab Mac on 2025-10-28.
//

import SwiftUI

/// The little grey workout tag that says the activity name
@ViewBuilder func activityTag(activityType: ActivityTypeEnum) -> some View {
    //Inner
    HStack {
        Circle()
            .stroke(lineWidth: 2)
            .foregroundStyle(.white)
            .frame(height:12)
            
        Text(activityType.displayName)
            .font(.zenHeadline)
            .foregroundStyle(.white)
            .frame(maxHeight: .infinity)
            .padding(.bottom, 3)
        Spacer()
            
    }
    .frame(width: 98, height: 20)
    .padding(.vertical, 6)
    .padding(.leading, 10)
    .background(
        RoundedRectangle(cornerRadius: 8)
            .fill(jet)
    )
}

//MARK: Gradient Outline Button
struct GradientOutlineButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 10
    var lineWidth: CGFloat = 1
    
    func makeBody(configuration: Configuration) -> some View {
  
        let radGrad = RadialGradient(colors: [ash, vermillion], center: .bottomLeading, startRadius: 0.0, endRadius: 400.0)
        //let gradient = AngularGradient(colors: [ash,ash, vermillion], center: .bottomLeading)

        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity) // remove if you don't want full-width
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(radGrad, lineWidth: lineWidth)
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.03 : 0.06),
                    radius: configuration.isPressed ? 6 : 12,
                    x: 0, y: configuration.isPressed ? 1 : 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

//MARK: Ash Text Editor
struct AshTextEditor: View {
    var fillColor: Color = Color(.systemGray6)
    var minH: CGFloat = 120
    @Binding var text: String
    var placeholder: String = "Tell the agents about your session"
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.body)
                .padding(12)
                .frame(minHeight: minH, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(fillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ash, lineWidth: 1)
                )
                .scrollContentBackground(.hidden) // iOS 16+
                .textInputAutocapitalization(.sentences)
                .focused($isFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                }

            if text.isEmpty && isFocused == false {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .allowsHitTesting(false) // let taps through to the editor
            }
        }
    }
}
