import Foundation

// MARK: - Command Protocol
protocol Command {
    func execute() throws -> CommandResult
    var description: String { get }
}

// MARK: - Command Result
enum CommandResult {
    case success(message: String?)
    case calculationResult(Double)
    case exit
    case display(content: String)
}

// MARK: - Command Types
enum CommandType: String, CaseIterable {
    case quit = "quit"
    case exit = "exit"
    case q = "q"
    case help = "help"
    case h = "h"
    case question = "?"
    case clear = "clear"
    case cls = "cls"
    case history = "history"
    case record = "record"
    case ans = "ans"
    case vars = "vars"
    case variables = "variables"
    
    var aliases: [String] {
        switch self {
        case .quit: return ["quit", "exit", "q"]
        case .help: return ["help", "h", "?"]
        case .clear: return ["clear", "cls"]
        case .vars: return ["vars", "variables"]
        default: return [rawValue]
        }
    }
}

// MARK: - Concrete Commands
class QuitCommand: Command {
    private let displayManager: DisplayManager
    
    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        displayManager.showGoodbye()
        
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        let script = """
        osascript -e 'tell application "Terminal" to close (every window whose frontmost is true)' & sleep 0.1 & kill -9 $PPID
        """
        process.arguments = ["-c", script]
        try? process.run()
        usleep(300000)
        #endif
        
        return .exit
    }
    
    var description: String { "退出计算器" }
}

class HelpCommand: Command {
    private let displayManager: DisplayManager
    
    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        displayManager.showHelp()
        return .success(message: nil)
    }
    
    var description: String { "显示帮助信息" }
}

class ClearCommand: Command {
    private let displayManager: DisplayManager
    
    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        displayManager.clearScreen()
        return .success(message: nil)
    }
    
    var description: String { "清除屏幕" }
}

class HistoryCommand: Command {
    private let historyManager: HistoryManager
    private let displayManager: DisplayManager
    
    init(historyManager: HistoryManager, displayManager: DisplayManager) {
        self.historyManager = historyManager
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        let history = historyManager.getFormattedHistory()
        displayManager.showHistory(history)
        return .success(message: nil)
    }
    
    var description: String { "显示计算历史" }
}

class RecordCommand: Command {
    private let fileManager: FileOperationsManager
    private let displayManager: DisplayManager
    
    init(fileManager: FileOperationsManager, displayManager: DisplayManager) {
        self.fileManager = fileManager
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        let result = fileManager.saveHistoryToFile()
        switch result {
        case .success(let filename):
            displayManager.showSuccessMessage("历史记录已保存到: \(filename)")
        case .failure(let error):
            displayManager.showError(CalculatorError.invalidExpression(message: error.localizedDescription))
        }
        return .success(message: nil)
    }
    
    var description: String { "保存历史记录到文件" }
}

class AnswerCommand: Command {
    private let calculatorEngine: CalculatorEngine
    private let displayManager: DisplayManager
    
    init(calculatorEngine: CalculatorEngine, displayManager: DisplayManager) {
        self.calculatorEngine = calculatorEngine
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        if let answer = calculatorEngine.getPreviousAnswer() {
            displayManager.showResult(answer)
        } else {
            displayManager.showMessage("没有可用的上一次结果")
        }
        return .success(message: nil)
    }
    
    var description: String { "显示上一次计算结果" }
}

class VariablesCommand: Command {
    private let calculatorEngine: CalculatorEngine
    private let displayManager: DisplayManager
    
    init(calculatorEngine: CalculatorEngine, displayManager: DisplayManager) {
        self.calculatorEngine = calculatorEngine
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        let variables = calculatorEngine.getVariables()
        displayManager.showVariables(variables)
        return .success(message: nil)
    }
    
    var description: String { "显示所有定义的变量" }
}

class DrawCommand: Command {
    private let functionExpression: String
    private let calculatorEngine: CalculatorEngine
    private let displayManager: DisplayManager
    
    init(functionExpression: String, calculatorEngine: CalculatorEngine, displayManager: DisplayManager) {
        self.functionExpression = functionExpression
        self.calculatorEngine = calculatorEngine
        self.displayManager = displayManager
    }
    
    func execute() throws -> CommandResult {
        let plotter = FunctionPlotter(calculator: calculatorEngine)
        let plot = try plotter.plotFunction(functionExpression)
        return .display(content: plot)
    }
    
    var description: String { "绘制函数图像: \(functionExpression)" }
}

class CalculationCommand: Command {
    private let expression: String
    private let calculatorEngine: CalculatorEngine
    private let historyManager: HistoryManager
    
    init(expression: String, calculatorEngine: CalculatorEngine, historyManager: HistoryManager) {
        self.expression = expression
        self.calculatorEngine = calculatorEngine
        self.historyManager = historyManager
    }
    
    func execute() throws -> CommandResult {
        let result = try calculatorEngine.evaluate(expression)
        historyManager.addEntry(expression, result: result)
        return .calculationResult(result)
    }
    
    var description: String { "计算表达式: \(expression)" }
}

// MARK: - Command Factory
class CommandFactory {
    private let displayManager: DisplayManager
    private let calculatorEngine: CalculatorEngine
    private let historyManager: HistoryManager
    private let fileManager: FileOperationsManager
    
    init(displayManager: DisplayManager, calculatorEngine: CalculatorEngine, 
         historyManager: HistoryManager, fileManager: FileOperationsManager) {
        self.displayManager = displayManager
        self.calculatorEngine = calculatorEngine
        self.historyManager = historyManager
        self.fileManager = fileManager
    }
    
    func createCommand(from input: String) -> Command {
        let trimmedInput = input.trimmed
        let lowercaseInput = trimmedInput.lowercased()
        
        // Check for draw command - supports draw(y=f(x)) format
        if lowercaseInput.hasPrefix("draw(") && lowercaseInput.hasSuffix(")") {
            return DrawCommand(
                functionExpression: trimmedInput,
                calculatorEngine: calculatorEngine,
                displayManager: displayManager
            )
        }
        
        // Check for built-in commands
        for commandType in CommandType.allCases {
            if commandType.aliases.contains(lowercaseInput) {
                return createBuiltInCommand(type: commandType)
            }
        }
        
        // Default to calculation command
        return CalculationCommand(
            expression: trimmedInput,
            calculatorEngine: calculatorEngine,
            historyManager: historyManager
        )
    }
    
    private func createBuiltInCommand(type: CommandType) -> Command {
        switch type {
        case .quit, .exit, .q:
            return QuitCommand(displayManager: displayManager)
        case .help, .h, .question:
            return HelpCommand(displayManager: displayManager)
        case .clear, .cls:
            return ClearCommand(displayManager: displayManager)
        case .history:
            return HistoryCommand(historyManager: historyManager, displayManager: displayManager)
        case .record:
            return RecordCommand(fileManager: fileManager, displayManager: displayManager)
        case .ans:
            return AnswerCommand(calculatorEngine: calculatorEngine, displayManager: displayManager)
        case .vars, .variables:
            return VariablesCommand(calculatorEngine: calculatorEngine, displayManager: displayManager)
        }
    }
}

// MARK: - Command Processor
class CommandProcessor {
    private let commandFactory: CommandFactory
    private let displayManager: DisplayManager
    
    init(commandFactory: CommandFactory, displayManager: DisplayManager) {
        self.commandFactory = commandFactory
        self.displayManager = displayManager
    }
    
    func processInput(_ input: String) -> Bool {
        guard !input.trimmed.isEmpty else {
            return true // Continue running
        }
        
        let command = commandFactory.createCommand(from: input)
        
        do {
            let result = try command.execute()
            
            switch result {
            case .success(let message):
                if let message = message {
                    displayManager.showMessage(message)
                }
                return true
                
            case .calculationResult(let value):
                displayManager.showResult(value)
                return true
                
            case .exit:
                return false
                
            case .display(let content):
                displayManager.showMessage(content)
                return true
            }
            
        } catch let error as CalculatorError {
            displayManager.showError(error)
            return true
            
        } catch {
            // 捕获所有未处理的异常
            displayManager.showError(CalculatorError.invalidExpression(message: "输入格式错误，输入 help 查看帮助"))
            return true
        }
    }
}