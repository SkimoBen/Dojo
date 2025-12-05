//
//  ActivityModel.swift
//  Multi-Agent-Coach
//
//  Created by Ben Pearman on 2025-10-08.
//

import Foundation

/// Top level ActivityType container
enum ActivityTypeEnum: String, CaseIterable, Identifiable, Codable{
    case climbing
    case running
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .climbing: "Climbing"
        case .running:  "Running"
        }
    }
}

//MARK: Enums

enum ClimbStyle: String, CaseIterable, Codable{
    case redpoint
    case flash
    case onSite  
    case nosend
    var displayName: String {
        switch self {
        case .redpoint: return "Redpoint"
        case .flash:    return "Flash"
        case .onSite:   return "On-Site"
        case .nosend:    return "-"
        }
    }

    init?(from string: String) {
        switch string.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") {
        case "redpoint": self = .redpoint
        case "flash":    self = .flash
        case "onsite":   self = .onSite
        case "nosend":   self = .nosend
        default: return nil
        }
    }
}

// MARK: - Shared "Grade" protocol that can be passed to views
protocol Grade: Codable, Hashable  {
    /// Display string, e.g., "5.11C" or "V7"
    var display: String { get }
    /// A total order for sorting and comparisons within the same scale
    var orderIndex: Int { get }
    /// Parse a user string into a concrete grade of this type
    init?(from string: String)
}

// MARK: - Universal grade wrapper you can encode/decode
enum GradeValue: Hashable, Codable, Comparable, Grade{
    case yds(YDSGrade)
    case v(VGrade)

    // MARK: Grade protocol
    var display: String {
        switch self {
        case .yds(let g): return g.display
        case .v(let g):   return g.display
        }
    }

    var orderIndex: Int {
        switch self {
        case .yds(let g): return g.orderIndex
        case .v(let g):   return g.orderIndex
        }
    }

    /// Parses either scale from loose user input.
    init?(from string: String) {
        if let y = YDSGrade(from: string) { self = .yds(y); return }
        if let v = VGrade(from: string)   { self = .v(v);   return }
        return nil
    }

    // MARK: Comparable
    static func < (lhs: GradeValue, rhs: GradeValue) -> Bool {
        // Define a stable cross-scale order if you like; here we keep scales separate:
        switch (lhs, rhs) {
        case (.yds(let a), .yds(let b)): return a < b
        case (.v(let a),   .v(let b)):   return a < b
        case (.yds, .v):                return true   // YDS sorts before V (choose any rule you prefer)
        case (.v,   .yds):              return false
        }
    }
}

// MARK: - V-Scale (bouldering) V0 ... V17
enum VGrade: String, CaseIterable, Codable, Comparable, Grade {
    case v0  = "V0"
    case v1  = "V1"
    case v2  = "V2"
    case v3  = "V3"
    case v4  = "V4"
    case v5  = "V5"
    case v6  = "V6"
    case v7  = "V7"
    case v8  = "V8"
    case v9  = "V9"
    case v10 = "V10"
    case v11 = "V11"
    case v12 = "V12"
    case v13 = "V13"
    case v14 = "V14"
    case v15 = "V15"
    case v16 = "V16"
    case v17 = "V17"

    var display: String { rawValue.uppercased() }

    var orderIndex: Int {
        // Declared order defines comparison
        return VGrade.allCases.firstIndex(of: self) ?? 0
    }

    static func < (lhs: VGrade, rhs: VGrade) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }

    /// Convenience: parse loose user strings like "v7", "V07", "7", or " v  10 "
    init?(from string: String) {
        let s = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: " ", with: "")

        // Normalize to something like "V7"
        let normalized: String
        if s.hasPrefix("V") {
            // Strip any leading zeros after V
            let digits = s.dropFirst().trimmingCharacters(in: CharacterSet(charactersIn: "0"))
            normalized = "V" + (digits.isEmpty ? "0" : digits)
        } else if let _ = s.first, s.first!.isNumber {
            // Bare number like "7" -> "V7"
            let digits = s.trimmingCharacters(in: .whitespaces)
            normalized = "V" + digits
        } else {
            return nil
        }

        // Only V0...V17 are valid
        if let match = VGrade.allCases.first(where: { $0.rawValue.uppercased() == normalized }) {
            self = match
        } else {
            self = VGrade.allCases.first(where: { $0.rawValue == "V0" && normalized == "V0" }) ?? .v0
            guard normalized.hasPrefix("V"),
                  let n = Int(normalized.dropFirst()),
                  (0...17).contains(n),
                  let exact = VGrade(rawValue: "V\(n)") else {
                return nil
            }
            self = exact
        }
    }
}

// MARK: - YDS Grade (hard-coded list)
enum YDSGrade: String, CaseIterable, Codable, Comparable, Grade{
    // 5.4 ... 5.9
    case g5_4  = "5.4"
    case g5_5  = "5.5"
    case g5_6  = "5.6"
    case g5_7  = "5.7"
    case g5_8  = "5.8"
    case g5_9  = "5.9"

    // 5.10a-d
    case g5_10a = "5.10a"
    case g5_10b = "5.10b"
    case g5_10c = "5.10c"
    case g5_10d = "5.10d"

    // 5.11a-d
    case g5_11a = "5.11a"
    case g5_11b = "5.11b"
    case g5_11c = "5.11c"
    case g5_11d = "5.11d"

    // 5.12a-d
    case g5_12a = "5.12a"
    case g5_12b = "5.12b"
    case g5_12c = "5.12c"
    case g5_12d = "5.12d"

    // 5.13a-d
    case g5_13a = "5.13a"
    case g5_13b = "5.13b"
    case g5_13c = "5.13c"
    case g5_13d = "5.13d"

    // 5.14a-d
    case g5_14a = "5.14a"
    case g5_14b = "5.14b"
    case g5_14c = "5.14c"
    case g5_14d = "5.14d"

    // 5.15a-d
    case g5_15a = "5.15a"
    case g5_15b = "5.15b"
    case g5_15c = "5.15c"
    case g5_15d = "5.15d"

    var display: String { rawValue.uppercased() }  // e.g., "5.10C"
    
    var orderIndex: Int {
            YDSGrade.allCases.firstIndex(of: self) ?? 0
        }
    
    // Comparable by declared order
    static func < (lhs: YDSGrade, rhs: YDSGrade) -> Bool {
        guard let li = allCases.firstIndex(of: lhs),
              let ri = allCases.firstIndex(of: rhs) else { return false }
        return li < ri
    }

    // Convenience: try to parse loose user strings like "10c" or "5.9"
    init?(from string: String) {
        let s = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "-")

        let normalized: String
        if s.hasPrefix("5.") { normalized = s }
        else if s.hasPrefix("5") { normalized = "5." + s.dropFirst() }
        else if let first = s.first, first.isNumber { normalized = "5." + s }
        else { return nil }

        if let match = YDSGrade.allCases.first(where: { $0.rawValue == normalized }) {
            self = match
        } else {
            // accept uppercase letters too
            let lower = normalized.replacingOccurrences(of: "A", with: "a")
                                   .replacingOccurrences(of: "B", with: "b")
                                   .replacingOccurrences(of: "C", with: "c")
                                   .replacingOccurrences(of: "D", with: "d")
            guard let match = YDSGrade.allCases.first(where: { $0.rawValue == lower }) else { return nil }
            self = match
        }
    }
}



private extension Int {
    var ordinalString: String {
        guard self != 0 else { return "0" }
        let ones = self % 10, tens = (self / 10) % 10
        let suf = (tens == 1) ? "th" : (ones == 1 ? "st" : ones == 2 ? "nd" : ones == 3 ? "rd" : "th")
        return "\(self)\(suf)"
    }
}

func formattedActivityDate(_ date: Date) -> String {
    let month = date.formatted(.dateTime.month(.abbreviated))
    let comps = Calendar.current.dateComponents([.day, .year], from: date)
    let day = (comps.day ?? 0).ordinalString
    let year = comps.year ?? 0
    return "\(month) \(day) \(year)"
}
