//
//  ZenFontPreview.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-21.
//


import SwiftUI

struct ZenFontPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("Zen Large Title").font(.zenLargeTitle)
                    Text("Zen Title").font(.zenTitle)
                    Text("Zen Title 2").font(.zenTitle2)
                    Text("Zen Title 3").font(.zenTitle3)
                    
                    Text("Zen Headline").font(.zenHeadline)
                    Text("Zen Subheadline").font(.zenSubheadline)
                    Text("Zen Body").font(.zenBody)
                    Text("Zen Callout").font(.zenCallout)
                    Text("Zen Footnote").font(.zenFootnote)
                    Text("Zen Caption").font(.zenCaption)
                    Text("Zen Caption 2").font(.zenCaption2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(raspberry)
            }
            .padding()
        }
        .navigationTitle("Zen Font Preview")
    }
}

#Preview {
    ZenFontPreview()
}
