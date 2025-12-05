//
//  Extensions.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-09-21.
//

// Removed XC Interface and DS Store

import SwiftUI

//MARK: Color(hex:)
/// Use hex in Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        switch length {
        case 3: // RGB (12-bit)
            r = Double((rgb >> 8) & 0xF) / 15.0
            g = Double((rgb >> 4) & 0xF) / 15.0
            b = Double(rgb & 0xF) / 15.0
            a = 1.0
        case 6: // RRGGBB (24-bit)
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            a = 1.0
        case 8: // AARRGGBB (32-bit)
            a = Double((rgb >> 24) & 0xFF) / 255.0
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
        default:
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

public extension Font {
    private static let zenFamily = "Zen Maru Gothic"

    static var zenLargeTitle: Font {
        .custom(zenFamily, size: 46, relativeTo: .largeTitle).weight(.black)
    }

    static var zenTitle: Font {
        .custom(zenFamily, size: 32, relativeTo: .title).weight(.bold)
    }

    static var zenTitle2: Font {
        .custom(zenFamily, size: 30, relativeTo: .title2).weight(.medium)
    }

    static var zenTitle3: Font {
        .custom(zenFamily, size: 28, relativeTo: .title3).weight(.regular)
    }
    
    static var zenTitle4: Font {
        .custom(zenFamily, size: 28, relativeTo: .title3).weight(.black)
    }

    static var zenHeadline: Font {
        .custom(zenFamily, size: 17, relativeTo: .headline).weight(.black)
    }
    
    static var zenBigHeadline: Font {
        .custom(zenFamily, size: 23, relativeTo: .headline).weight(.black)
    }

    static var zenSubheadline: Font {
        .custom(zenFamily, size: 15, relativeTo: .subheadline).weight(.medium)
    }

    static var zenBody: Font {
        .custom(zenFamily, size: 17, relativeTo: .body).weight(.regular)
    }

    static var zenCallout: Font {
        .custom(zenFamily, size: 14, relativeTo: .callout).weight(.light)
    }

    static var zenFootnote: Font {
        .custom(zenFamily, size: 13, relativeTo: .footnote).weight(.regular)
    }

    static var zenCaption: Font {
        .custom(zenFamily, size: 13, relativeTo: .caption).weight(.bold)
    }

    static var zenCaption2: Font {
        .custom(zenFamily, size: 10, relativeTo: .caption2).weight(.light)
    }
}
extension UIFont {
    private static let zenFamily = "Zen Maru Gothic"
    static var zenCaption2: UIFont {
        // Match the SwiftUI font: .custom(zenFamily, size: 10, relativeTo: .caption2).weight(.light)
        let baseDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption2)
        let pointSize = baseDescriptor.pointSize  // Dynamic type size for caption2
        let customFont = UIFont(name: zenFamily, size: pointSize) ?? .systemFont(ofSize: pointSize, weight: .light)
        
        // Apply light weight explicitly
        if let descriptor = customFont.fontDescriptor.withSymbolicTraits([]) {
            return UIFont(descriptor: descriptor, size: 10).withWeight(.light)
        }
        return customFont
    }
}

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight]
        let descriptor = fontDescriptor.addingAttributes([.traits: traits])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}


extension View {
    /// Soft inner shadow panel (for ScrollViews, cards, etc.)
    func sunkenPanel(
        cornerRadius: CGFloat = 14,
        fill: some ShapeStyle = Color(.white),
        darkEdgeOpacity: CGFloat = 0.10,
        lightEdgeOpacity: CGFloat = 0.65
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(
                shape.fill(fill)
                    // slight dark inner edge (bottom)
                    .overlay(
                        shape
                            .stroke(Color.black.opacity(darkEdgeOpacity), lineWidth: 1)
                            .offset(y: 1)
                            .blur(radius: 1.2)
                            .mask(shape)
                    )
                    // subtle light inner edge (top)
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(lightEdgeOpacity), lineWidth: 1)
                            .offset(y: -1)
                            .blur(radius: 1.0)
                            .mask(shape)
                    )
            )
            .clipShape(shape) // ensure content stays within the rounded panel
            // optional ultra-subtle outer stroke to define the edge
            .overlay(shape.strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5))
    }
}


extension View {
    /// Converts any SwiftUI View into a UIImage.
    func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        // Set a fixed size based on content
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        // Render the view hierarchy to UIImage
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}



// For formatting TimeInterval (which is seconds) as min:seconds.
extension TimeInterval {
    var paceString: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


extension Date {
    var customFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE - MMM d"
        let base = formatter.string(from: self)
        
        // Add suffix for the day (st, nd, rd, th)
        let day = Calendar.current.component(.day, from: self)
        let suffix: String
        switch day {
        case 11, 12, 13: suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        
        // Replace the plain day number with the suffixed one
        return base.replacingOccurrences(of: "\(day)", with: "\(day)\(suffix)")
    }
    
    func formattedWithOrdinal() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy" // gives “June 14, 2025”
        let base = formatter.string(from: self)
        
        // Extract the day number to add “st/nd/rd/th”
        let day = Calendar.current.component(.day, from: self)
        let suffix: String
        switch day {
        case 11, 12, 13:
            suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        
        // Insert suffix right after the day number
        return base.replacingOccurrences(of: "\(day),", with: "\(day)\(suffix),")
    }
    
    // Gives "06/11/2025"
    var ddMMyyyy: String {
            self.formatted(Date.FormatStyle()
                .day(.twoDigits)
                .month(.twoDigits)
                .year(.defaultDigits))
        }
}


// MARK: - ISO 8601 date helpers (supports fractional seconds like the server output)
struct ISO8601DateFlex: Codable {
    /// Wrapper to encode/decode ISO 8601 with or without fractional seconds and 'Z'
    let date: Date

    init(_ date: Date) { self.date = date }

    init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        if let d = ISO8601DateFlex.fractional.date(from: s) ?? ISO8601DateFlex.basic.date(from: s) {
            self.date = d
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid ISO8601 date: \(s)"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        let s = ISO8601DateFlex.fractional.string(from: date)
        try c.encode(s)
    }

    // With fractional seconds (matches server: 2025-10-14T16:47:19.503265Z)
    private static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // Without fractional seconds (fallback)
    private static let basic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}
