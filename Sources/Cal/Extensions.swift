import Foundation

// MARK: - String Extensions
extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func distance(to index: String.Index) -> Int {
        return distance(from: startIndex, to: index)
    }
    
    func index(at offset: Int) -> String.Index {
        return index(startIndex, offsetBy: offset)
    }
    
    func substring(from offset: Int, length: Int) -> String {
        let start = index(startIndex, offsetBy: offset)
        let end = index(start, offsetBy: length)
        return String(self[start..<end])
    }
}

// MARK: - Double Extensions
extension Double {
    var isInteger: Bool {
        return floor(self) == self
    }
    
    var formattedString: String {
        if isInteger {
            return String(format: "%.0f", self)
        } else {
            return String(self)
        }
    }
    
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Array Extensions
extension Array where Element == String {
    func keepLast(_ count: Int) -> [String] {
        return Array(suffix(count))
    }
}

// MARK: - ANSI Colors
struct ANSIColor {
    static let red = "\u{001B}[31;1m"
    static let yellow = "\u{001B}[33;1m"
    static let green = "\u{001B}[32;1m"
    static let blue = "\u{001B}[34;1m"
    static let magenta = "\u{001B}[35;1m"
    static let cyan = "\u{001B}[36;1m"
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let underline = "\u{001B}[4m"
    static let brightRed = "\u{001B}[91m"
}

// MARK: - Math Constants
struct MathConstants {
    static let pi = Double.pi
    static let e = M_E
    static let tau = 2 * Double.pi
    static let goldenRatio = (1 + sqrt(5)) / 2
}

// MARK: - Input Validation
struct InputValidator {
    private static let validChars = CharacterSet(charactersIn: "0123456789.+-*/()abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,_= ")
    
    static func containsOnlyValidCharacters(_ input: String) -> Bool {
        return input.rangeOfCharacter(from: validChars.inverted) == nil
    }
    
    static func findInvalidCharacter(in input: String) -> (position: Int, character: Character)? {
        if let range = input.rangeOfCharacter(from: validChars.inverted) {
            let position = input.distance(from: input.startIndex, to: range.lowerBound)
            let character = input[range.lowerBound]
            return (position, character)
        }
        return nil
    }
}