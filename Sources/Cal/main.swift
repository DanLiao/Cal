#!/usr/bin/swift

import Foundation

// MARK: - Application Configuration
struct AppConfig {
    static let maxHistorySize = 50
    static let version = "2.0"
    static let appName = "Swift Calculator"
}

// MARK: - Main Application Class
class CalculatorApp {
    private let displayManager: DisplayManager
    private let calculatorEngine: CalculatorEngine
    private let historyManager: HistoryManager
    private let fileManager: FileOperationsManager
    private let commandProcessor: CommandProcessor
    private var initialExpression: String?
    
    init() {
        self.displayManager = DisplayManager()
        self.calculatorEngine = CalculatorEngine()
        self.historyManager = HistoryManager(maxSize: AppConfig.maxHistorySize)
        self.fileManager = FileOperationsManager(historyManager: historyManager)
        
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
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
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