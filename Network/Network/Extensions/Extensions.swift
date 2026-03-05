//
//  Generic.swift
//  Networking
//
//  Created by Salah Khaled on 03/03/2026.
//

import Foundation
import SwiftUI

// MARK: - Data Pretty Print
extension Data? {
    
    func prettyPrint(max: Int = 80) -> String {
        guard let data = self else { return "{ }" }
        
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            let truncatedObject = truncate(object, max: max)
            
            let prettyData = try JSONSerialization.data(withJSONObject: truncatedObject,
                                                        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            
            return String(decoding: prettyData, as: UTF8.self)
        } catch {
            return String(decoding: data, as: UTF8.self)
        }
    }
    
    
    // MARK: - Truncation
    private func truncate(_ value: Any, max: Int) -> Any {
        
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { truncate($0, max: max) }
            
        case let array as [Any]:
            return array.map { truncate($0, max: max) }
            
        case let string as String:
            if string.count > max {
                let visible = String(string.prefix(max))
                let remain = string.count - max
                return "\(visible)... + (\(remain) chars)"
            }
            return string
        default:
            return value
        }
    }
}


// MARK: - Header Pretty Print
extension Headers {
    func prettyPrint() -> String {
        
        guard !self.isEmpty else { return "[ ]" }
        let sorted = self.sorted { $0.key.lowercased() < $1.key.lowercased() }
        let maxLength = sorted.map { $0.key.count }.max() ?? 0
        
        return sorted.map { key, value in
            let paddedKey = key.padding(toLength: maxLength, withPad: " ", startingAt: 0)
            let key = paddedKey.contains(APIHeader.authorization) ? "🔐 " : ""
            return "   [\(paddedKey)]  \(key)\(value)"
        }
        .joined(separator: "\n")
    }
}


// MARK: - String
extension String {
    func truncated(_ max: Int) -> String {
        guard count > max else { return self }
        
        let visible = prefix(max)
        let remain = count - max
        return "\(visible)... + (\(remain) chars)"
    }
    
    func truncateToken(prefix: Int = 3, suffix: Int = 3) -> String {
        guard let spaceIndex = firstIndex(of: " ") else { return self }
        
        let scheme = self[..<spaceIndex]          // e.g. "Bearer"
        let tokenStart = index(after: spaceIndex) // start of token
        let token = self[tokenStart...]
        
        guard token.count > prefix + suffix else { return self }
        
        let start = token.index(token.startIndex, offsetBy: prefix)
        let end = token.index(token.endIndex, offsetBy: -suffix)
        
        return "\(scheme) \(token[..<start])...\(token[end...])"
    }
}



// MARK: - Decoding Error
extension DecodingError {
    
    var errorPath: String {
        switch self {
        case .typeMismatch(_, let context),
             .valueNotFound(_, let context),
             .keyNotFound(_, let context),
             .dataCorrupted(let context):
            
            let path = context.codingPath.map { $0.stringValue }.joined(separator: " ➡️ ")
            return "Decoding error at key: \(path) \n   \(context.debugDescription)"
            
        @unknown default:
            return self.localizedDescription
        }
    }
}


// MARK: - Status Code Color
extension Int {
    func color() -> Color {
        switch self {
        case 100..<200: return .blue
        case 200..<300: return .green
        case 300..<400: return .yellow
        case 400..<500: return .orange
        default: return .red
        }
    }
}


// MARK: - Copy
extension View {
    func copyable(title: String = String(localized: "copy"), text: String, color: Color = .blue) -> some View {
        self.modifier(CopyableModifier(title: title, text: text, color: color))
    }
    
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

fileprivate struct CopyableModifier: ViewModifier {
    let title: String
    let text: String
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing) {
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label(title, systemImage: "square.on.square")
                }
                .tint(color)
            }
            .contextMenu {
                Button(title) {
                    UIPasteboard.general.string = text
                }
            }
    }
}
