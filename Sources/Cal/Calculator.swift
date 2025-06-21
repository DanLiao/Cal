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
    internal let constants: [String: Double]
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
        
        // Create and evaluate NSExpression with comprehensive error handling
        let nsExpression: NSExpression
        let result: NSNumber
        
        // Check for various problematic patterns that NSExpression can't handle
        let problematicPatterns = [
            // Single equals (assignment, not comparison)
            "^[a-zA-Z][a-zA-Z0-9_]*\\s*=\\s*[^=].*",
            // Invalid operators
            "\\+\\+|\\-\\-|\\*\\*\\*|///|\\^\\^",
            // Invalid comparisons with undefined variables
            "[a-zA-Z][a-zA-Z0-9_]*\\s*(==|!=|>=|<=)\\s*[a-zA-Z][a-zA-Z0-9_]*",
            // Malformed expressions
            "^\\s*[+\\-*/^=]|[+\\-*/^=]\\s*$",
            ".*[+\\-*/^=]{2,}.*"
        ]
        
        for pattern in problematicPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: expr.utf16.count)
                if regex.firstMatch(in: expr, options: [], range: range) != nil {
                    throw CalculatorError.invalidExpression(message: "表达式格式错误，输入 help 查看帮助")
                }
            }
        }
        
        // Additional simple checks
        if expr.contains("=") && !expr.contains("==") && !expr.contains("!=") && !expr.contains(">=") && !expr.contains("<=") {
            throw CalculatorError.invalidExpression(message: "表达式格式错误，输入 help 查看帮助")
        }
        
        nsExpression = NSExpression(format: expr)
        
        guard let evaluatedResult = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber else {
            throw CalculatorError.invalidExpression(message: "无法计算表达式，输入 help 查看帮助")
        }
        result = evaluatedResult
        
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
    
    internal func processScientificNotation(_ expression: String) throws -> String {
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
    
    internal func fixDecimalFormats(_ expression: String) throws -> String {
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
    
    internal func processFunctions(_ expression: String) throws -> String {
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
    
    func getVariable(_ name: String) -> Double? {
        return variableManager.getVariable(name)
    }
    
    func setVariable(_ name: String, value: Double) {
        variableManager.setVariable(name, value: value)
    }
    
    func removeVariable(_ name: String) {
        variableManager.removeVariable(name)
    }
    
    func evaluateExpression(_ expression: String) throws -> Double {
        return try parser.parse(expression, previousAnswer: previousAnswer)
    }
    
    func evaluateExpressionForPlotting(_ expression: String) throws -> Double {
        // Special handling for plotting - don't apply the problematic pattern checks
        var expr = expression.trimmed
        
        // Replace previous answer
        if let answer = previousAnswer {
            expr = expr.replacingOccurrences(of: "ans", with: String(answer))
        }
        
        // Replace constants
        for (name, value) in parser.constants {
            expr = expr.replacingOccurrences(of: name, with: String(value))
        }
        
        // Replace variables
        for (name, value) in variableManager.getAllVariables() {
            expr = expr.replacingOccurrences(of: name, with: String(value))
        }
        
        // Handle scientific notation
        expr = try parser.processScientificNotation(expr)
        
        // Fix decimal formats
        expr = try parser.fixDecimalFormats(expr)
        
        // Process functions
        expr = try parser.processFunctions(expr)
        
        // Handle power operator (^ to **)
        expr = expr.replacingOccurrences(of: "^", with: "**")
        
        // Create and evaluate NSExpression
        let nsExpression = NSExpression(format: expr)
        
        guard let evaluatedResult = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber else {
            throw CalculatorError.invalidExpression(message: "无法计算表达式")
        }
        
        let doubleResult = evaluatedResult.doubleValue
        
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
}

// MARK: - Function Plotter
class FunctionPlotter {
    private let calculator: CalculatorEngine
    private let width: Int
    private let height: Int
    
    init(calculator: CalculatorEngine, width: Int = 80, height: Int = 24) {
        self.calculator = calculator
        self.width = width
        self.height = height
    }
    
    func plotFunction(_ functionExpression: String, xMin: Double = -10, xMax: Double = 10) throws -> String {
        // 解析函数表达式，支持 draw(y=f(x)) 格式
        var expression = functionExpression.trimmed
        
        // 移除 draw( 和 ) 包装
        if expression.hasPrefix("draw(") && expression.hasSuffix(")") {
            expression = String(expression.dropFirst(5).dropLast(1))
        }
        
        // 移除 y= 前缀
        if expression.hasPrefix("y=") {
            expression = String(expression.dropFirst(2))
        }
        
        expression = expression.trimmed
        
        var plot = Array(repeating: Array(repeating: " ", count: width), count: height)
        
        // 计算步长
        let xStep = (xMax - xMin) / Double(width - 1)
        let yValues = try calculateYValues(expression: expression, xMin: xMin, xMax: xMax, step: xStep)
        
        // 过滤无效值
        let validYValues = yValues.filter { $0.isFinite }
        guard !validYValues.isEmpty else {
            return "函数无有效值，无法绘制图像"
        }
        
        // 找到y值的范围
        let yMin = validYValues.min()!
        let yMax = validYValues.max()!
        let yRange = yMax - yMin
        
        // 避免除零
        guard yRange > 0.0001 else {
            return "函数值变化范围太小，无法绘制图像"
        }
        
        // 绘制坐标轴
        drawAxes(&plot, xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)
        
        // 绘制函数曲线
        for (i, y) in yValues.enumerated() {
            if y.isFinite {
                let plotY = Int((yMax - y) / yRange * Double(height - 1))
                if plotY >= 0 && plotY < height && i >= 0 && i < width {
                    plot[plotY][i] = "*"
                }
            }
        }
        
        // 转换为字符串
        var result = ""
        for row in plot {
            result += row.joined() + "\n"
        }
        
        // 添加坐标信息
        result += "X: [\(String(format: "%.2f", xMin)), \(String(format: "%.2f", xMax))]  "
        result += "Y: [\(String(format: "%.2f", yMin)), \(String(format: "%.2f", yMax))]\n"
        result += "函数: y = \(expression)\n"
        
        return result
    }
    
    private func calculateYValues(expression: String, xMin: Double, xMax: Double, step: Double) throws -> [Double] {
        var yValues: [Double] = []
        var x = xMin
        
        while x <= xMax {
            // 临时设置 x 变量
            let originalX = calculator.getVariable("x")
            calculator.setVariable("x", value: x)
            
            do {
                let y = try calculator.evaluateExpressionForPlotting(expression)
                yValues.append(y)
            } catch {
                yValues.append(Double.nan)
            }
            
            // 恢复原始 x 值
            if let originalValue = originalX {
                calculator.setVariable("x", value: originalValue)
            } else {
                calculator.removeVariable("x")
            }
            
            x += step
        }
        
        return yValues
    }
    
    private func drawAxes(_ plot: inout [[String]], xMin: Double, xMax: Double, yMin: Double, yMax: Double) {
        // 绘制 Y 轴（x=0的位置）
        if xMin <= 0 && xMax >= 0 {
            let xZeroIndex = Int((-xMin) / (xMax - xMin) * Double(width - 1))
            if xZeroIndex >= 0 && xZeroIndex < width {
                for row in 0..<height {
                    plot[row][xZeroIndex] = "|"
                }
            }
        }
        
        // 绘制 X 轴（y=0的位置）
        if yMin <= 0 && yMax >= 0 {
            let yZeroIndex = Int((yMax - 0) / (yMax - yMin) * Double(height - 1))
            if yZeroIndex >= 0 && yZeroIndex < height {
                for col in 0..<width {
                    plot[yZeroIndex][col] = "-"
                }
            }
        }
        
        // 绘制原点
        if xMin <= 0 && xMax >= 0 && yMin <= 0 && yMax >= 0 {
            let xZeroIndex = Int((-xMin) / (xMax - xMin) * Double(width - 1))
            let yZeroIndex = Int((yMax - 0) / (yMax - yMin) * Double(height - 1))
            if xZeroIndex >= 0 && xZeroIndex < width && yZeroIndex >= 0 && yZeroIndex < height {
                plot[yZeroIndex][xZeroIndex] = "+"
            }
        }
    }
}