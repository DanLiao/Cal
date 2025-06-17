#!/usr/bin/swift

import Foundation

// 全局变量
var results = [String]()  // 存储计算历史
var previousAnswer: Double? = nil  // 存储上一次的计算结果
let maxHistorySize = 50  // 历史记录最大数量
var initialExpression: String? = nil  // 初始表达式
var commandHistory: [String] = []
var historyIndex: Int = 0

// 解析命令行参数
func parseCommandLineArguments() {
    let args = CommandLine.arguments
    if args.count > 1 {
        // 命令行中的第一个参数是要计算的表达式
        initialExpression = args[1]
    }
}

// 处理URL协议启动参数
func processCommandLineArguments() {
    let args = CommandLine.arguments
    if args.count > 1 {
        // 如果有参数，检查是否是URL协议
        let arg = args[1]
        if arg.hasPrefix("swiftcalculator://") {
            // 解析URL
            if let url = URL(string: arg), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                // 解析查询参数
                if let queryItems = components.queryItems {
                    for item in queryItems {
                        if item.name == "expression", let value = item.value {
                            // URL解码
                            initialExpression = value.removingPercentEncoding
                            break
                        }
                    }
                }
            }
        } else {
            // 直接作为表达式处理
            initialExpression = arg
        }
    }
}

// 获取命令类型
enum Command {
    case quit
    case exit
    case help
    case clear
    case history
    case record
    case ans
}

// 获取命令
func getCommand(_ input: String) -> Command? {
    switch input.lowercased() {
    case "q", "quit", "exit":
        return .quit
    case "help", "h", "?":
        return .help
    case "clear", "cls":
        return .clear
    case "history":
        return .history
    case "record":
        return .record
    case "ans":
        return .ans
    default:
        return nil
    }
}

// 显示帮助信息
func showHelp() {
    print("""
    \(ANSIColor.cyan)Swift 计算器使用帮助\(ANSIColor.reset)
    基本操作:
      + 加法
      - 减法
      * 乘法
      / 除法
    函数:
      sqrt(x)  - 平方根
      pow(x,y) - x的y次方
      log(x)   - 自然对数
      sin(x)   - 正弦函数
      cos(x)   - 余弦函数
      tan(x)   - 正切函数
    常量:
      pi - 圆周率(3.14159...)
      e  - 自然对数的底(2.71828...)
    浮点数格式:
      支持标准格式(3.14)、无小数部分(2.)和无整数部分(.5)
    特殊变量:
      ans - 前一次计算的结果
    命令:
      q/quit/exit - 退出程序
      help/h/?    - 显示帮助
      clear/cls   - 清屏
      history     - 显示历史记录
      record      - 保存结果到文件
      ans         - 显示上一次计算的结果
    """)
}

// 清屏
func clearScreen() {
    print("\u{1B}[2J\u{1B}[H", terminator: "")
}

// 记录历史
func saveToHistory(_ input: String, _ result: Double) {
    let historyEntry = "\(input) = \(result)"
    if results.count >= maxHistorySize {
        results.removeFirst()
    }
    results.append(historyEntry)
}

// 显示历史记录
func showHistory() {
    if results.isEmpty {
        print("没有历史记录")
        return
    }
    
    print("\(ANSIColor.cyan)计算历史记录:\(ANSIColor.reset)")
    for (index, result) in results.enumerated() {
        print("\(index + 1). \(result)")
    }
}

// 显示启动动画
func showStartupAnimation() {
    let frame1 = " _____       _ \n" +
                "/ ____|     | |\n" +
                "| |     __ _ | |\n" +
                "| |    / _` || |\n" +
                "| |___| (_| || |\n" +
                " \\_____\\__,_||_|"
    
    let frame2 = " _____       _  _____\n" +
                "/ ____|     | |/ ____|\n" +
                "| |     __ _ | | |     \n" +
                "| |    / _` || | |     \n" +
                "| |___| (_| || | |____ \n" +
                " \\_____\\__,_||_|\\_____| "
    
    let frame3 = " _____       _  _____ _    _ _            _             \n" +
                "/ ____|     | |/ ____| |  | | |          | |            \n" +
                "| |     __ _ | | |    | |  | | | __ _  ___| |_ ___  _ __ \n" +
                "| |    / _` || | |    | |  | | |/ _` |/ __| __/ _ \\| '__|\n" +
                "| |___| (_| || | |____| |__| | | (_| | (__| || (_) | |   \n" +
                " \\_____\\__,_||_|\\_____|\\____/|_|\\__,_|\\___|\\__\\___/|_|   "
    
    let frames = [frame1, frame2, frame3]
    
    // 清屏
    print("\u{1B}[2J\u{1B}[H", terminator: "")
    
    for frame in frames {
        // 清屏
        print("\u{1B}[2J\u{1B}[H", terminator: "")
        // 打印帧
        print(frame)
        // 等待一小段时间
        usleep(300000) // 300毫秒
    }
    
    // 短暂延迟
    usleep(500000) // 500毫秒
    
    // 清屏
    print("\u{1B}[2J\u{1B}[H", terminator: "")
}

// 保存结果到文件
func saveResultsToFile() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HH"
    
    // 获取存储记录的目录
    var recordDir = ""
    
    // 如果设置了APP_PATH环境变量，使用与应用程序同级的record目录
    if let appPath = ProcessInfo.processInfo.environment["APP_PATH"] {
        // 获取应用程序所在的目录（上一级目录）
        let appDirPath = URL(fileURLWithPath: appPath).deletingLastPathComponent().path
        recordDir = "\(appDirPath)/record"
    } else if FileManager.default.fileExists(atPath: "/Volumes/M4backup/Cal/record") {
        // 使用固定路径作为备选
        recordDir = "/Volumes/M4backup/Cal/record"
    } else {
        // 如果都不可用，使用当前目录下的record
        recordDir = "record"
    }
    
    // 如果record目录不存在，创建它
    if !FileManager.default.fileExists(atPath: recordDir) {
        do {
            try FileManager.default.createDirectory(atPath: recordDir, withIntermediateDirectories: true)
            print("已创建记录目录: \(recordDir)")
        } catch {
            print("无法创建record目录: \(error.localizedDescription)")
        }
    }
    
    var filename = "\(recordDir)/\(dateFormatter.string(from: Date())).txt"
    
    // 检查文件是否存在，如果存在，添加分钟
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: filename) {
        dateFormatter.dateFormat = "yyyyMMdd_HHmm"
        filename = "\(recordDir)/\(dateFormatter.string(from: Date())).txt"
    }
    
    do {
        let resultText = results.joined(separator: "\n")
        try resultText.write(toFile: filename, atomically: true, encoding: .utf8)
        print("结果已保存到 \(filename)")
    } catch {
        print("保存失败: \(error.localizedDescription)")
    }
}

// 自定义错误类型
enum CalculatorError: Error {
    case invalidCharacter(position: Int, char: Character)
    case missingParenthesis(position: Int, type: ParenthesisType)
    case invalidOperator(position: Int, operatorString: String)
    case invalidFunction(position: Int, name: String)
    case invalidExpression(message: String)
    case emptyExpression
}

enum ParenthesisType {
    case open
    case close
}

// ANSI颜色代码
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

// 高亮显示错误位置
func highlightError(expression: String, position: Int, length: Int = 1) -> String {
    var result = expression + "\n"
    if position < expression.count {
        // 添加高亮
        result += String(repeating: " ", count: position)
        result += ANSIColor.brightRed + String(repeating: "^", count: max(1, length)) + ANSIColor.reset
    }
    return result
}

// 验证函数调用格式
func validateFunctionCall(_ expression: String) throws {
    let functionNames = ["sqrt", "pow", "log", "sin", "cos", "tan"]
    
    for funcName in functionNames {
        if expression.contains(funcName) {
            // 检查函数调用格式
            let pattern = "\(funcName)\\s*\\("
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            if let matches = regex?.matches(in: expression, options: [], range: NSRange(location: 0, length: expression.utf16.count)) {
                for match in matches {
                    let funcRange = NSRange(location: match.range.location, length: funcName.count)
                    if let range = Range(funcRange, in: expression) {
                        let funcPos = expression.distance(from: expression.startIndex, to: range.lowerBound)
                        
                        // 检查括号是否匹配
                        let startPos = match.range.location + match.range.length - 1 // 左括号的位置
                        var depth = 1
                        var i = startPos + 1
                        
                        while i < expression.count && depth > 0 {
                            let index = expression.index(expression.startIndex, offsetBy: i)
                            if expression[index] == "(" {
                                depth += 1
                            } else if expression[index] == ")" {
                                depth -= 1
                            }
                            i += 1
                        }
                        
                        if depth > 0 {
                            // 缺少右括号
                            throw CalculatorError.missingParenthesis(position: startPos, type: .close)
                        }
                        
                        // 特殊检查pow函数，确保有逗号
                        if funcName == "pow" {
                            let endPos = i - 1
                            let start = expression.index(expression.startIndex, offsetBy: startPos + 1)
                            let end = expression.index(expression.startIndex, offsetBy: endPos)
                            let args = String(expression[start..<end])
                            
                            if !args.contains(",") {
                                throw CalculatorError.invalidFunction(position: funcPos, name: "pow需要两个参数，以逗号分隔")
                            }
                        }
                    }
                }
            } else {
                // 函数名字存在但格式不正确
                if let funcPos = expression.range(of: funcName)?.lowerBound {
                    let position = expression.distance(from: expression.startIndex, to: funcPos)
                    throw CalculatorError.invalidFunction(position: position, name: funcName)
                }
            }
        }
    }
}

// 计算表达式
func evaluateExpression(_ expression: String) throws -> Double? {
    // 检查表达式是否为空
    if expression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        throw CalculatorError.emptyExpression
    }
    
    // 验证函数调用格式
    try validateFunctionCall(expression)
    
    // 替换 ans 为上一次的结果
    var expr = expression
    if let answer = previousAnswer, expr.contains("ans") {
        expr = expr.replacingOccurrences(of: "ans", with: String(answer))
    }
    
    // 替换常量
    expr = expr.replacingOccurrences(of: "pi", with: String(Double.pi))
    expr = expr.replacingOccurrences(of: "e", with: String(M_E))
    
    // 修复浮点数格式
    // 处理形如 "2." 的情况，转换为 "2.0"
    let decimalRegex = try NSRegularExpression(pattern: "(\\d+)\\.(\\D|$)", options: [])
    expr = decimalRegex.stringByReplacingMatches(
        in: expr,
        options: [],
        range: NSRange(location: 0, length: expr.utf16.count),
        withTemplate: "$1.0$2"
    )
    
    // 处理形如 ".2" 的情况，转换为 "0.2"
    let leadingDecimalRegex = try NSRegularExpression(pattern: "(^|\\D)\\.(\\d+)", options: [])
    expr = leadingDecimalRegex.stringByReplacingMatches(
        in: expr,
        options: [],
        range: NSRange(location: 0, length: expr.utf16.count),
        withTemplate: "$10.$2"
    )
    
    // 特殊处理pow函数，因为NSExpression对pow函数有特殊要求
    if expr.contains("pow(") {
        // 先检查是否有直接的pow函数调用
        let powRegex = try? NSRegularExpression(pattern: "pow\\((\\d+\\.?\\d*),\\s*(\\d+\\.?\\d*)\\)", options: [])
        if let matches = powRegex?.matches(in: expr, options: [], range: NSRange(location: 0, length: expr.utf16.count)) {
            for match in matches.reversed() { // 从后向前替换，避免位置变化
                if let baseRange = Range(match.range(at: 1), in: expr),
                   let exponentRange = Range(match.range(at: 2), in: expr) {
                    let base = expr[baseRange]
                    let exponent = expr[exponentRange]
                    
                    // 计算pow结果
                    if let baseValue = Double(String(base)), 
                       let exponentValue = Double(String(exponent)) {
                        let result = pow(baseValue, exponentValue)
                        
                        // 用结果替换pow表达式
                        if let range = Range(match.range, in: expr) {
                            expr = expr.replacingCharacters(in: range, with: String(result))
                        }
                    }
                }
            }
        }
    }
    
    // 处理三角函数
    let trigFunctions = ["sin", "cos", "tan"]
    for func_name in trigFunctions {
        let pattern = "\(func_name)\\((\\d+\\.?\\d*)\\)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        if let matches = regex?.matches(in: expr, options: [], range: NSRange(location: 0, length: expr.utf16.count)) {
            for match in matches.reversed() {
                if let argRange = Range(match.range(at: 1), in: expr) {
                    let arg = expr[argRange]
                    
                    if let argValue = Double(String(arg)) {
                        var result: Double = 0
                        
                        switch func_name {
                        case "sin":
                            result = sin(argValue)
                        case "cos":
                            result = cos(argValue)
                        case "tan":
                            result = tan(argValue)
                        default:
                            break
                        }
                        
                        if let range = Range(match.range, in: expr) {
                            expr = expr.replacingCharacters(in: range, with: String(result))
                        }
                    }
                }
            }
        }
    }
    
    // 验证表达式只包含合法字符
    let validChars = CharacterSet(charactersIn: "0123456789.+-*/() ansqrtlogicopie,")
    if let invalidRange = expr.rangeOfCharacter(from: validChars.inverted) {
        let position = expr.distance(from: expr.startIndex, to: invalidRange.lowerBound)
        let charIndex = expr.index(expr.startIndex, offsetBy: position)
        throw CalculatorError.invalidCharacter(position: position, char: expr[charIndex])
    }
    
    // 验证括号是否匹配
    var stack = [Int]()
    for (index, char) in expr.enumerated() {
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
    
    // 验证运算符使用是否正确
    let operatorRegex = try! NSRegularExpression(pattern: "[+\\-*/]{2,}|\\*\\*|//")
    if let match = operatorRegex.firstMatch(in: expr, range: NSRange(expr.startIndex..., in: expr)) {
        let position = expr.distance(from: expr.startIndex, to: Range(match.range, in: expr)!.lowerBound)
        let range = Range(match.range, in: expr)!
        let operatorString = String(expr[range])
        throw CalculatorError.invalidOperator(position: position, operatorString: operatorString)
    }
    
    // 处理其他特殊函数
    expr = expr.replacingOccurrences(of: "sqrt", with: "sqrt:")
    expr = expr.replacingOccurrences(of: "log", with: "log:")
    
    // 创建表达式
    let expression = NSExpression(format: expr)
    
    // 尝试计算表达式的值
    do {
        if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.doubleValue
        } else {
            throw CalculatorError.invalidExpression(message: "无法计算表达式，请检查格式")
        }
    } catch {
        throw CalculatorError.invalidExpression(message: error.localizedDescription)
    }
}

// 显示欢迎信息
func showWelcome() {
    clearScreen()
    
    // ASCII艺术标题
    print("""
    \(ANSIColor.cyan)
     _____       _      _____       _      
    /  __ \\     | |    /  __ \\     | |     
    | /  \\/ __ _| |    | /  \\/ __ _| | ___ 
    | |    / _` | |    | |    / _` | |/ __|
    | \\__/\\ (_| | |    | \\__/\\ (_| | | (__ 
     \\____/\\__,_|_|     \\____/\\__,_|_|\\___|
    \(ANSIColor.reset)
    """)
    
    print("\(ANSIColor.green)欢迎使用Swift计算器！\(ANSIColor.reset)")
    print("输入 'help' 或 '?' 查看帮助, 输入 'q' 退出")
    print("")
    
    // 如果有初始表达式，先尝试计算
    if let expression = initialExpression {
        print(">> \(expression)")
        processInput(expression)
    }
}

// 运行计算器
func runCalculator() {
    showWelcome()
    
    while true {
        print("\(ANSIColor.green)>> \(ANSIColor.reset)", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            continue
        }
        
        processInput(input)
    }
}

// 显示再见动画
func showGoodbyeAnimation() {
    clearScreen()
    
    // ASCII艺术再见
    print("""
    \(ANSIColor.cyan)
      _____                 _  _               _ 
     / ____|               | || |             | |
    | |  __   ___    ___   | || |__   _   _  | |_  
    | | |_ | / _ \\  / _ \\  | || '_ \\ | | | | | __|
    | |__| || (_) || (_) | | || |_) || |_| | | |_ 
     \\_____| \\___/  \\___/  |_||_.__/  \\__, |  \\__|
                                        __/ |     
                                       |___/      
    \(ANSIColor.reset)
    """)
    
    print("\(ANSIColor.green)感谢使用Swift计算器，下次再见！\(ANSIColor.reset)")
    
    // 延迟1秒后退出
    fflush(stdout)
    sleep(1)
}

// 处理用户输入
func processInput(_ input: String) {
    if input.isEmpty {
        // 忽略空输入
        return
    }
    
    if let cmd = getCommand(input) {
        switch cmd {
        case .quit, .exit:
            // 显示再见动画
            showGoodbyeAnimation()
            
            #if os(macOS)
            // 使用一个新进程执行命令来关闭当前终端窗口
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            
            // 创建一个命令，通过osascript关闭终端窗口，并立即终止当前进程
            let script = """
            osascript -e 'tell application "Terminal" to close (every window whose frontmost is true)' & sleep 0.1 & kill -9 $PPID
            """
            
            process.arguments = ["-c", script]
            
            // 通过异步执行确保我们的进程能够正常退出
            try? process.run()
            
            // 让当前程序等待一会，确保bash命令有机会执行
            usleep(300000) // 300毫秒
            #endif
            
            // 正常退出程序
            exit(0)
            
        case .help:
            showHelp()
        case .clear:
            clearScreen()
        case .history:
            showHistory()
        case .record:
            saveResultsToFile()
        case .ans:
            if let answer = previousAnswer {
                print("\(ANSIColor.green)\(answer)\(ANSIColor.reset)")
            } else {
                print("没有可用的上一次结果")
            }
        }
    } else {
        // 处理表达式计算
        do {
            if let result = try evaluateExpression(input) {
                // 打印计算结果
                print("\(ANSIColor.green)\(result)\(ANSIColor.reset)")
                
                // 保存到历史记录
                saveToHistory(input, result)
                previousAnswer = result
            } else {
                throw CalculatorError.invalidExpression(message: "无法计算表达式，请检查格式")
            }
        } catch CalculatorError.emptyExpression {
            print("\(ANSIColor.brightRed)错误：表达式为空\(ANSIColor.reset)")
            print("请输入有效的计算表达式")
        } catch CalculatorError.invalidCharacter(let position, let char) {
            print("\(ANSIColor.brightRed)错误：无效字符 '\(char)'\(ANSIColor.reset)")
            print(highlightError(expression: input, position: position, length: 1))
            print("建议：请移除无效字符或替换为有效字符")
        } catch CalculatorError.missingParenthesis(let position, let type) {
            let missingType = type == .open ? "缺少左括号" : "缺少右括号"
            print("\(ANSIColor.brightRed)错误：\(missingType)\(ANSIColor.reset)")
            print(highlightError(expression: input, position: position, length: 1))
            print("建议：请在适当位置添加\(type == .open ? "(" : ")")括号")
        } catch CalculatorError.invalidOperator(let position, let operatorString) {
            print("\(ANSIColor.brightRed)错误：无效运算符 '\(operatorString)'\(ANSIColor.reset)")
            print(highlightError(expression: input, position: position, length: operatorString.count))
            print("建议：运算符不能连续使用，请检查并修正")
            print("有效的运算符：+, -, *, /")
        } catch CalculatorError.invalidFunction(let position, let name) {
            print("\(ANSIColor.brightRed)错误：无效函数调用 '\(name)'\(ANSIColor.reset)")
            print(highlightError(expression: input, position: position, length: name.count))
            print("建议：请检查函数名及参数格式")
            print("支持的函数：sqrt(x), pow(x,y), log(x), sin(x), cos(x), tan(x)")
        } catch CalculatorError.invalidExpression(let message) {
            print("\(ANSIColor.brightRed)错误：无效的表达式\(ANSIColor.reset)")
            print(highlightError(expression: input, position: 0, length: input.count))
            print("原因：\(message)")
            print("建议：请检查表达式格式和运算符使用")
        } catch {
            print("\(ANSIColor.brightRed)未知错误：\(error.localizedDescription)\(ANSIColor.reset)")
        }
    }
}

// 优雅退出
func handleSignal() {
    signal(SIGINT) { _ in
        // 显示再见动画
        showGoodbyeAnimation()
        
        #if os(macOS)
        // 使用一个新进程执行命令来关闭当前终端窗口
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        // 创建一个命令，通过osascript关闭终端窗口，并立即终止当前进程
        let script = """
        osascript -e 'tell application "Terminal" to close (every window whose frontmost is true)' & sleep 0.1 & kill -9 $PPID
        """
        
        process.arguments = ["-c", script]
        
        // 通过异步执行确保我们的进程能够正常退出
        try? process.run()
        
        // 让当前程序等待一会，确保bash命令有机会执行
        usleep(300000) // 300毫秒
        #endif
        
        // 正常退出程序
        exit(0)
    }
}

// 主函数
func main() {
    // 解析命令行参数
    parseCommandLineArguments()
    
    // 设置信号处理
    handleSignal()
    
    // 运行计算器
    runCalculator()
}

// 启动程序
main() 


