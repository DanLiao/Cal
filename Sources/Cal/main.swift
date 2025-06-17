#!/usr/bin/swift

import Foundation
import Darwin

// MARK: - Application Configuration
struct AppConfig {
    static let maxHistorySize = 50
    static let version = "2.0"
    static let appName = "Swift Calculator"
}

// MARK: - Terminal Input Manager
class TerminalInputManager {
    private var originalTermios: termios = termios()
    private var historyNavigator: HistoryNavigator
    
    init(historyManager: HistoryManager) {
        self.historyNavigator = HistoryNavigator(historyManager: historyManager)
    }
    
    func enableRawMode() {
        tcgetattr(STDIN_FILENO, &originalTermios)
        var raw = originalTermios
        raw.c_lflag &= ~(UInt(ECHO | ICANON))
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    }
    
    func disableRawMode() {
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
    }
    
    func readInputWithHistory() -> String? {
        enableRawMode()
        defer { disableRawMode() }
        
        var input = ""
        var cursor = 0
        
        while true {
            let char = getchar()
            
            // Handle Ctrl+C
            if char == 3 {
                print("\n")
                raise(SIGINT)
                return nil
            }
            
            // Handle Enter
            if char == 13 || char == 10 {
                print("\n")
                historyNavigator.addToHistory(input)
                return input.isEmpty ? nil : input
            }
            
            // Handle Backspace
            if char == 127 || char == 8 {
                if cursor > 0 {
                    input.remove(at: input.index(input.startIndex, offsetBy: cursor - 1))
                    cursor -= 1
                    redrawLine(input, cursor: cursor)
                }
                continue
            }
            
            // Handle Escape sequences (Arrow keys)
            if char == 27 {
                let next1 = getchar()
                if next1 == 91 { // [
                    let next2 = getchar()
                    switch next2 {
                    case 65: // Up arrow
                        if let historyLine = historyNavigator.navigateUp() {
                            input = historyLine
                            cursor = input.count
                            redrawLine(input, cursor: cursor)
                        }
                    case 66: // Down arrow
                        if let historyLine = historyNavigator.navigateDown() {
                            input = historyLine
                            cursor = input.count
                            redrawLine(input, cursor: cursor)
                        } else {
                            input = ""
                            cursor = 0
                            redrawLine(input, cursor: cursor)
                        }
                    case 67: // Right arrow
                        if cursor < input.count {
                            cursor += 1
                            print("\u{1B}[C", terminator: "")
                            fflush(stdout)
                        }
                    case 68: // Left arrow
                        if cursor > 0 {
                            cursor -= 1
                            print("\u{1B}[D", terminator: "")
                            fflush(stdout)
                        }
                    default:
                        break
                    }
                }
                continue
            }
            
            // Handle regular characters
            if char >= 32 && char <= 126 {
                let character = Character(UnicodeScalar(Int(char))!)
                if cursor == input.count {
                    input.append(character)
                    cursor += 1
                    print(character, terminator: "")
                    fflush(stdout)
                } else {
                    input.insert(character, at: input.index(input.startIndex, offsetBy: cursor))
                    cursor += 1
                    redrawLine(input, cursor: cursor)
                }
            }
        }
    }
    
    private func redrawLine(_ input: String, cursor: Int) {
        // Clear current line
        print("\r\u{1B}[K", terminator: "")
        // Show prompt and input
        print("\u{1B}[32m>> \u{1B}[0m\(input)", terminator: "")
        // Position cursor
        if cursor < input.count {
            let moves = input.count - cursor
            print("\u{1B}[\(moves)D", terminator: "")
        }
        fflush(stdout)
    }
}

// MARK: - History Navigator
class HistoryNavigator {
    private let historyManager: HistoryManager
    private var currentIndex: Int = -1
    private var inputHistory: [String] = []
    
    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
        loadHistory()
    }
    
    private func loadHistory() {
        inputHistory = historyManager.getHistory().map { $0.input }
        currentIndex = inputHistory.count
    }
    
    func addToHistory(_ input: String) {
        if !input.isEmpty && input != inputHistory.last {
            inputHistory.append(input)
            if inputHistory.count > AppConfig.maxHistorySize {
                inputHistory.removeFirst()
            }
        }
        currentIndex = inputHistory.count
    }
    
    func navigateUp() -> String? {
        if currentIndex > 0 {
            currentIndex -= 1
            return inputHistory[currentIndex]
        }
        return nil
    }
    
    func navigateDown() -> String? {
        if currentIndex < inputHistory.count - 1 {
            currentIndex += 1
            return inputHistory[currentIndex]
        } else if currentIndex == inputHistory.count - 1 {
            currentIndex += 1
            return ""
        }
        return nil
    }
}

// MARK: - Main Application Class
class CalculatorApp {
    private let displayManager: DisplayManager
    private let calculatorEngine: CalculatorEngine
    private let historyManager: HistoryManager
    private let fileManager: FileOperationsManager
    private let commandProcessor: CommandProcessor
    private let inputManager: TerminalInputManager
    private var initialExpression: String?
    
    init() {
        self.displayManager = DisplayManager()
        self.calculatorEngine = CalculatorEngine()
        self.historyManager = HistoryManager(maxSize: AppConfig.maxHistorySize)
        self.fileManager = FileOperationsManager(historyManager: historyManager)
        self.inputManager = TerminalInputManager(historyManager: historyManager)
        
        let commandFactory = CommandFactory(
            displayManager: displayManager,
            calculatorEngine: calculatorEngine,
            historyManager: historyManager,
            fileManager: fileManager
        )
        
        self.commandProcessor = CommandProcessor(
            commandFactory: commandFactory,
            displayManager: displayManager
        )
    }
    
    func run() {
        setupSignalHandling()
        parseCommandLineArguments()
        showWelcome()
        runMainLoop()
    }
    
    private func setupSignalHandling() {
        signal(SIGINT) { _ in
            let displayManager = DisplayManager()
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
            
            exit(0)
        }
    }
    
    private func parseCommandLineArguments() {
        let args = CommandLine.arguments
        guard args.count > 1 else { return }
        
        let arg = args[1]
        
        // Handle URL protocol
        if arg.hasPrefix("swiftcalculator://") {
            if let url = URL(string: arg),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                
                for item in queryItems {
                    if item.name == "expression", let value = item.value {
                        initialExpression = value.removingPercentEncoding
                        break
                    }
                }
            }
        } else {
            // Direct expression
            initialExpression = arg
        }
    }
    
    private func showWelcome() {
        displayManager.showWelcome()
        
        // Process initial expression if provided
        if let expression = initialExpression {
            displayManager.showMessage(">> \(expression)")
            _ = commandProcessor.processInput(expression)
        }
    }
    
    private func runMainLoop() {
        while true {
            displayManager.showPrompt()
            
            guard let input = inputManager.readInputWithHistory()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                continue
            }
            
            let shouldContinue = commandProcessor.processInput(input)
            if !shouldContinue {
                break
            }
        }
    }
}

// MARK: - Entry Point
func main() {
    let app = CalculatorApp()
    app.run()
}

// Run the application
main()