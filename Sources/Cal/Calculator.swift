import Foundation
// Expression library types are accessed via ExpressionBridge.swift typealiases
// (CalcExpression, CalcExpressionSymbol, etc.) to avoid conflict with
// Foundation.Expression<each Input, Output> introduced in macOS 15.

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
// Note: sqrt, abs, pow, log, log10, sin, cos, tan, round, ceil, floor are built into
// the Expression library. These structs serve as reference implementations and are
// used directly by FactorialFunction. Others can be registered if custom behavior is needed.

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
        guard n <= AppConfig.maxFactorialInput else {
            throw CalculatorError.invalidExpression(message: "factorial参数过大(最大\(AppConfig.maxFactorialInput))")
        }

        if n == 0 { return 1.0 }
        var result = 1.0
        for i in 1...n {
            result *= Double(i)
        }
        return result
    }
}

// MARK: - Expression Parser
// Uses the Expression library (nicklockwood/Expression) as the evaluation engine.
// Built-in functions: sqrt, abs, pow, log, log10, log2, sin, cos, tan, asin, acos, atan,
//                     atan2, round, ceil, floor, min, max, exp
// Custom additions:   factorial, ^ (power operator), math constants (pi, e, tau, golden)
class ExpressionParser {
    private let variableManager: VariableStorageManager
    private let constants: [String: Double]
    private let factorial = FactorialFunction()

    init(variableManager: VariableStorageManager) {
        self.variableManager = variableManager
        self.constants = [
            "pi": MathConstants.pi,
            "e":  MathConstants.e,
            "tau": MathConstants.tau,
            "golden": MathConstants.goldenRatio
        ]
    }

    func parse(_ expression: String, previousAnswer: Double?) throws -> Double {
        guard !expression.trimmed.isEmpty else {
            throw CalculatorError.emptyExpression
        }

        // Use CalcExpression* aliases from ExpressionBridge.swift to avoid
        // ambiguity with Foundation.Expression (macOS 15+).
        var symbols: [CalcExpressionSymbol: CalcExpressionEvaluator] = [:]

        // Override ^ as power operator (library default is bitwise XOR)
        symbols[CalcExpressionSymbol.infix("^")] = { args in pow(args[0], args[1]) }

        // factorial is not in the library's default function set
        symbols[CalcExpressionSymbol.function("factorial", arity: CalcExpressionArity.exactly(1))] = { [factorial] args in
            try factorial.evaluate(args)
        }

        // Math constants
        for (name, value) in constants {
            symbols[CalcExpressionSymbol.variable(name)] = { _ in value }
        }

        // User-defined variables
        for (name, value) in variableManager.getAllVariables() {
            symbols[CalcExpressionSymbol.variable(name)] = { _ in value }
        }

        // Previous answer
        if let answer = previousAnswer {
            symbols[CalcExpressionSymbol.variable("ans")] = { _ in answer }
        }

        do {
            let expr = CalcExpression(expression.trimmed, symbols: symbols)
            let result = try expr.evaluate()
            guard result.isFinite else {
                throw result.isInfinite
                    ? CalculatorError.divisionByZero
                    : CalculatorError.invalidExpression(message: "计算结果无效")
            }
            return result
        } catch let calcError as CalculatorError {
            throw calcError
        } catch let exprError as CalcExpressionError {
            if case .undefinedSymbol(let symbol) = exprError,
               case .variable(let name) = symbol {
                throw CalculatorError.undefinedVariable(name)
            }
            throw CalculatorError.invalidExpression(message: "\(exprError)")
        } catch {
            throw CalculatorError.invalidExpression(message: error.localizedDescription)
        }
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

    // Used by FunctionPlotter; delegates to evaluateExpression now that
    // Expression library handles all preprocessing internally.
    func evaluateExpressionForPlotting(_ expression: String) throws -> Double {
        return try evaluateExpression(expression)
    }
}

// MARK: - Function Plotter
class FunctionPlotter {
    private let calculator: CalculatorEngine
    private let width: Int
    private let height: Int

    init(calculator: CalculatorEngine, width: Int = 0, height: Int = 0) {
        self.calculator = calculator
        if width > 0 && height > 0 {
            self.width = width
            self.height = height
        } else {
            let size = Self.terminalSize()
            self.width = size.width
            self.height = size.height
        }
    }

    private static func terminalSize() -> (width: Int, height: Int) {
        var ws = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0, ws.ws_col > 10, ws.ws_row > 5 {
            // Leave 4 rows for axis labels and info lines
            return (Int(ws.ws_col), max(10, Int(ws.ws_row) - 4))
        }
        return (AppConfig.plotDefaultWidth, AppConfig.plotDefaultHeight)
    }

    func plotFunction(_ functionExpression: String, xMin: Double = -10, xMax: Double = 10) throws -> String {
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

        let xStep = (xMax - xMin) / Double(width - 1)
        let yValues = try calculateYValues(expression: expression, xMin: xMin, xMax: xMax, step: xStep)

        let validYValues = yValues.filter { $0.isFinite }
        guard !validYValues.isEmpty else {
            return "函数无有效值，无法绘制图像"
        }

        let yMin = validYValues.min()!
        let yMax = validYValues.max()!
        let yRange = yMax - yMin

        guard yRange > AppConfig.plotMinYRange else {
            return "函数值变化范围太小，无法绘制图像"
        }

        drawAxes(&plot, xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)

        for (i, y) in yValues.enumerated() {
            if y.isFinite {
                let plotY = Int((yMax - y) / yRange * Double(height - 1))
                if plotY >= 0 && plotY < height && i >= 0 && i < width {
                    plot[plotY][i] = "*"
                }
            }
        }

        var result = ""
        for row in plot {
            result += row.joined() + "\n"
        }

        result += "X: [\(String(format: "%.2f", xMin)), \(String(format: "%.2f", xMax))]  "
        result += "Y: [\(String(format: "%.2f", yMin)), \(String(format: "%.2f", yMax))]\n"
        result += "函数: y = \(expression)\n"

        return result
    }

    private func calculateYValues(expression: String, xMin: Double, xMax: Double, step: Double) throws -> [Double] {
        var yValues: [Double] = []
        var x = xMin

        while x <= xMax {
            let originalX = calculator.getVariable("x")
            calculator.setVariable("x", value: x)

            do {
                let y = try calculator.evaluateExpressionForPlotting(expression)
                yValues.append(y)
            } catch {
                yValues.append(Double.nan)
            }

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
        // Y 轴（x=0的位置）
        if xMin <= 0 && xMax >= 0 {
            let xZeroIndex = Int((-xMin) / (xMax - xMin) * Double(width - 1))
            if xZeroIndex >= 0 && xZeroIndex < width {
                for row in 0..<height {
                    plot[row][xZeroIndex] = "|"
                }
            }
        }

        // X 轴（y=0的位置）
        if yMin <= 0 && yMax >= 0 {
            let yZeroIndex = Int((yMax - 0) / (yMax - yMin) * Double(height - 1))
            if yZeroIndex >= 0 && yZeroIndex < height {
                for col in 0..<width {
                    plot[yZeroIndex][col] = "-"
                }
            }
        }

        // 原点
        if xMin <= 0 && xMax >= 0 && yMin <= 0 && yMax >= 0 {
            let xZeroIndex = Int((-xMin) / (xMax - xMin) * Double(width - 1))
            let yZeroIndex = Int((yMax - 0) / (yMax - yMin) * Double(height - 1))
            if xZeroIndex >= 0 && xZeroIndex < width && yZeroIndex >= 0 && yZeroIndex < height {
                plot[yZeroIndex][xZeroIndex] = "+"
            }
        }
    }
}
