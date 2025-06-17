import Foundation

// MARK: - Calculator Errors
enum CalculatorError: Error, LocalizedError {
    case invalidCharacter(position: Int, char: Character)
    case missingParenthesis(position: Int, type: ParenthesisType)
    case invalidOperator(position: Int, operatorString: String)
    case invalidFunction(position: Int, name: String)
    case invalidExpression(message: String)
    case emptyExpression
    case divisionByZero
    case invalidVariableName(String)
    case undefinedVariable(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyExpression:
            return "表达式为空"
        case .invalidCharacter(_, let char):
            return "无效字符: \(char)"
        case .divisionByZero:
            return "除零错误"
        case .invalidVariableName(let name):
            return "无效变量名: \(name)"
        case .undefinedVariable(let name):
            return "未定义变量: \(name)"
        default:
            return "计算错误"
        }
    }
}

enum ParenthesisType {
    case open, close
}

// MARK: - Math Function Strategy Protocol
protocol MathFunctionStrategy {
    func evaluate(_ args: [Double]) throws -> Double
    var argumentCount: Int { get }
    var name: String { get }
}

// MARK: - Concrete Math Function Strategies
struct SqrtFunction: MathFunctionStrategy {
    let name = "sqrt"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        guard args[0] >= 0 else {
            throw CalculatorError.invalidExpression(message: "sqrt的参数必须非负")
        }
        return sqrt(args[0])
    }
}

struct AbsFunction: MathFunctionStrategy {
    let name = "abs"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        return abs(args[0])
    }
}

struct PowFunction: MathFunctionStrategy {
    let name = "pow"
    let argumentCount = 2
    
    func evaluate(_ args: [Double]) throws -> Double {
        return pow(args[0], args[1])
    }
}

struct LogFunction: MathFunctionStrategy {
    let name = "log"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        guard args[0] > 0 else {
            throw CalculatorError.invalidExpression(message: "log的参数必须为正数")
        }
        return log(args[0])
    }
}

struct Log10Function: MathFunctionStrategy {
    let name = "log10"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        guard args[0] > 0 else {
            throw CalculatorError.invalidExpression(message: "log10的参数必须为正数")
        }
        return log10(args[0])
    }
}

struct SinFunction: MathFunctionStrategy {
    let name = "sin"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        return sin(args[0])
    }
}

struct CosFunction: MathFunctionStrategy {
    let name = "cos"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        return cos(args[0])
    }
}

struct TanFunction: MathFunctionStrategy {
    let name = "tan"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        return tan(args[0])
    }
}

struct RoundFunction: MathFunctionStrategy {
    let name = "round"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        return round(args[0])
    }
}

struct CeilFunction: MathFunctionStrategy {
    let name = "ceil"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        return ceil(args[0])
    }
}

struct FloorFunction: MathFunctionStrategy {
    let name = "floor"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        return floor(args[0])
    }
}

struct FactorialFunction: MathFunctionStrategy {
    let name = "factorial"
    let argumentCount = 1
    
    func evaluate(_ args: [Double]) throws -> Double {
        let n = Int(args[0])
        guard n >= 0 && args[0] == Double(n) else {
            throw CalculatorError.invalidExpression(message: "factorial需要非负整数")
        }
        guard n <= 20 else {
            throw CalculatorError.invalidExpression(message: "factorial参数过大(最大20)")
        }
        
        var result = 1.0
        for i in 1...n {
            result *= Double(i)
        }
        return result
    }
}

// MARK: - Expression Parser
class ExpressionParser {
    private let functions: [String: MathFunctionStrategy]
    private let constants: [String: Double]
    private let variableManager: VariableStorageManager
    
    // Pre-compiled regex patterns for performance
    private let decimalRegex: NSRegularExpression
    private let leadingDecimalRegex: NSRegularExpression
    private let scientificNotationRegex: NSRegularExpression
    private let operatorRegex: NSRegularExpression
    
    init(variableManager: VariableStorageManager) {
        self.variableManager = variableManager
        
        // Initialize function strategies
        let functionList: [MathFunctionStrategy] = [
            SqrtFunction(), AbsFunction(), PowFunction(), LogFunction(), Log10Function(),
            SinFunction(), CosFunction(), TanFunction(), RoundFunction(),
            CeilFunction(), FloorFunction(), FactorialFunction()
        ]
        
        self.functions = Dictionary(uniqueKeysWithValues: functionList.map { ($0.name, $0) })
        
        // Initialize constants
        self.constants = [
            "pi": MathConstants.pi,
            "e": MathConstants.e,
            "tau": MathConstants.tau,
            "golden": MathConstants.goldenRatio
        ]
        
        // Pre-compile regex patterns
        self.decimalRegex = try! NSRegularExpression(pattern: "(\\d+)\\.(\\D|$)", options: [])
        self.leadingDecimalRegex = try! NSRegularExpression(pattern: "(^|\\D)\\.(\\d+)", options: [])
        self.scientificNotationRegex = try! NSRegularExpression(pattern: "(\\d+(?:\\.\\d+)?)e([+-]?\\d+)", options: .caseInsensitive)
        self.operatorRegex = try! NSRegularExpression(pattern: "[+\\-*/^]{2,}|\\*\\*|//", options: [])
    }
    
    func parse(_ expression: String, previousAnswer: Double?) throws -> Double {
        guard !expression.trimmed.isEmpty else {
            throw CalculatorError.emptyExpression
        }
        
        var expr = expression.trimmed
        
        // Replace previous answer
        if let answer = previousAnswer {
            expr = expr.replacingOccurrences(of: "ans", with: String(answer))
        }
        
        // Replace constants
        for (name, value) in constants {
            expr = expr.replacingOccurrences(of: name, with: String(value))
        }
        
        // Replace variables
        for (name, value) in variableManager.getAllVariables() {
            expr = expr.replacingOccurrences(of: name, with: String(value))
        }
        
        // Handle scientific notation
        expr = try processScientificNotation(expr)
        
        // Fix decimal formats
        expr = try fixDecimalFormats(expr)
        
        // Validate expression
        try validateExpression(expr)
        
        // Process functions
        expr = try processFunctions(expr)
        
        // Handle power operator (^ to pow)
        expr = expr.replacingOccurrences(of: "^", with: "**")
        
        // Create and evaluate NSExpression
        let nsExpression = NSExpression(format: expr)
        
        guard let result = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber else {
            throw CalculatorError.invalidExpression(message: "无法计算表达式")
        }
        
        let doubleResult = result.doubleValue
        
        // Check for division by zero or invalid results
        guard doubleResult.isFinite else {
            if doubleResult.isInfinite {
                throw CalculatorError.divisionByZero
            } else {
                throw CalculatorError.invalidExpression(message: "计算结果无效")
            }
        }
        
        return doubleResult
    }
    
    private func processScientificNotation(_ expression: String) throws -> String {
        let matches = scientificNotationRegex.matches(in: expression, options: [], range: NSRange(location: 0, length: expression.utf16.count))
        
        var result = expression
        for match in matches.reversed() {
            if let mantissaRange = Range(match.range(at: 1), in: expression),
               let exponentRange = Range(match.range(at: 2), in: expression),
               let fullRange = Range(match.range, in: expression) {
                
                let mantissa = Double(String(expression[mantissaRange])) ?? 0
                let exponent = Int(String(expression[exponentRange])) ?? 0
                let value = mantissa * pow(10.0, Double(exponent))
                
                result = result.replacingCharacters(in: fullRange, with: String(value))
            }
        }
        
        return result
    }
    
    private func fixDecimalFormats(_ expression: String) throws -> String {
        var expr = expression
        
        // Fix "2." format to "2.0"
        expr = decimalRegex.stringByReplacingMatches(
            in: expr,
            options: [],
            range: NSRange(location: 0, length: expr.utf16.count),
            withTemplate: "$1.0$2"
        )
        
        // Fix ".2" format to "0.2"
        expr = leadingDecimalRegex.stringByReplacingMatches(
            in: expr,
            options: [],
            range: NSRange(location: 0, length: expr.utf16.count),
            withTemplate: "$10.$2"
        )
        
        return expr
    }
    
    private func validateExpression(_ expression: String) throws {
        // Check for invalid characters
        if let (position, char) = InputValidator.findInvalidCharacter(in: expression) {
            throw CalculatorError.invalidCharacter(position: position, char: char)
        }
        
        // Validate parentheses
        try validateParentheses(expression)
        
        // Validate operators
        try validateOperators(expression)
    }
    
    private func validateParentheses(_ expression: String) throws {
        var stack = [Int]()
        for (index, char) in expression.enumerated() {
            if char == "(" {
                stack.append(index)
            } else if char == ")" {
                if stack.isEmpty {
                    throw CalculatorError.missingParenthesis(position: index, type: .open)
                }
                stack.removeLast()
            }
        }
        if !stack.isEmpty {
            throw CalculatorError.missingParenthesis(position: stack.last!, type: .close)
        }
    }
    
    private func validateOperators(_ expression: String) throws {
        if let match = operatorRegex.firstMatch(in: expression, range: NSRange(expression.startIndex..., in: expression)) {
            let position = expression.distance(from: expression.startIndex, to: Range(match.range, in: expression)!.lowerBound)
            let range = Range(match.range, in: expression)!
            let operatorString = String(expression[range])
            throw CalculatorError.invalidOperator(position: position, operatorString: operatorString)
        }
    }
    
    private func processFunctions(_ expression: String) throws -> String {
        var expr = expression
        
        // Process each function type
        for (name, strategy) in functions {
            expr = try processFunction(expr, name: name, strategy: strategy)
        }
        
        return expr
    }
    
    private func processFunction(_ expression: String, name: String, strategy: MathFunctionStrategy) throws -> String {
        let pattern = "\(name)\\(([^)]+)\\)"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: expression, options: [], range: NSRange(location: 0, length: expression.utf16.count))
        
        var result = expression
        for match in matches.reversed() {
            if let argsRange = Range(match.range(at: 1), in: expression),
               let fullRange = Range(match.range, in: expression) {
                
                let argsString = String(expression[argsRange])
                let args = try parseArguments(argsString, expectedCount: strategy.argumentCount)
                let functionResult = try strategy.evaluate(args)
                
                result = result.replacingCharacters(in: fullRange, with: String(functionResult))
            }
        }
        
        return result
    }
    
    private func parseArguments(_ argsString: String, expectedCount: Int) throws -> [Double] {
        let argStrings = argsString.split(separator: ",").map { String($0).trimmed }
        
        guard argStrings.count == expectedCount else {
            throw CalculatorError.invalidExpression(message: "函数参数数量不正确，期望\(expectedCount)个参数")
        }
        
        var args: [Double] = []
        for argString in argStrings {
            guard let value = Double(argString) else {
                throw CalculatorError.invalidExpression(message: "无效的函数参数: \(argString)")
            }
            args.append(value)
        }
        
        return args
    }
}

// MARK: - Main Calculator Engine
class CalculatorEngine {
    private let parser: ExpressionParser
    private let variableManager: VariableStorageManager
    private var previousAnswer: Double?
    
    init() {
        self.variableManager = VariableStorageManager()
        self.parser = ExpressionParser(variableManager: variableManager)
    }
    
    func evaluate(_ input: String) throws -> Double {
        // Check if it's a variable assignment
        if let (varName, expression) = parseVariableAssignment(input) {
            try validateVariableName(varName)
            let value = try parser.parse(expression, previousAnswer: previousAnswer)
            variableManager.setVariable(varName, value: value)
            previousAnswer = value
            return value
        }
        
        // Regular expression evaluation
        let result = try parser.parse(input, previousAnswer: previousAnswer)
        previousAnswer = result
        return result
    }
    
    func getPreviousAnswer() -> Double? {
        return previousAnswer
    }
    
    func getVariables() -> [String: Double] {
        return variableManager.getAllVariables()
    }
    
    func clearVariables() {
        variableManager.clearVariables()
    }
    
    private func parseVariableAssignment(_ input: String) -> (String, String)? {
        let parts = input.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
            let varPart = String(parts[0]).trimmed
            let exprPart = String(parts[1]).trimmed
            
            if varPart.hasPrefix("let ") {
                let varName = String(varPart.dropFirst(4)).trimmed
                return (varName, exprPart)
            }
        }
        return nil
    }
    
    private func validateVariableName(_ name: String) throws {
        let regex = try NSRegularExpression(pattern: "^[a-zA-Z][a-zA-Z0-9_]*$", options: [])
        let range = NSRange(location: 0, length: name.utf16.count)
        
        if regex.firstMatch(in: name, options: [], range: range) == nil {
            throw CalculatorError.invalidVariableName(name)
        }
    }
}