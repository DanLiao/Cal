import Foundation

// MARK: - Display Manager
class DisplayManager {
    func clearScreen() {
        print("\u{1B}[2J\u{1B}[H", terminator: "")
    }
    
    func showWelcome() {
        clearScreen()
        
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
        
        print("\(ANSIColor.green)欢迎使用Swift计算器 v2.0！\(ANSIColor.reset)")
        print("输入 'help' 查看帮助, 输入 'quit' 退出")
        print("")
    }
    
    func showGoodbye() {
        clearScreen()
        
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
        
        print("\(ANSIColor.green)感谢使用Swift计算器，再见！\(ANSIColor.reset)")
        fflush(stdout)
        usleep(1000000) // 1 second
    }
    
    func showPrompt() {
        print("\(ANSIColor.green)>> \(ANSIColor.reset)", terminator: "")
    }
    
    func showResult(_ result: Double) {
        print("\(ANSIColor.green)\(result.formattedString)\(ANSIColor.reset)")
    }
    
    func showError(_ error: CalculatorError) {
        switch error {
        case .emptyExpression:
            print("\(ANSIColor.brightRed)错误：表达式为空\(ANSIColor.reset)")
            print("请输入有效的计算表达式")
            
        case .invalidCharacter(_, let char):
            print("\(ANSIColor.brightRed)错误：无效字符 '\(char)'\(ANSIColor.reset)")
            print("建议：请移除无效字符或替换为有效字符")
            
        case .missingParenthesis(_, let type):
            let missingType = type == .open ? "缺少左括号" : "缺少右括号"
            print("\(ANSIColor.brightRed)错误：\(missingType)\(ANSIColor.reset)")
            print("建议：请在适当位置添加\(type == .open ? "(" : ")")括号")
            
        case .invalidOperator(_, let operatorString):
            print("\(ANSIColor.brightRed)错误：无效运算符 '\(operatorString)'\(ANSIColor.reset)")
            print("建议：运算符不能连续使用，请检查并修正")
            print("有效的运算符：+, -, *, /, ^")
            
        case .invalidFunction(_, let name):
            print("\(ANSIColor.brightRed)错误：无效函数调用 '\(name)'\(ANSIColor.reset)")
            print("建议：请检查函数名及参数格式")
            showSupportedFunctions()
            
        case .invalidExpression(let message):
            print("\(ANSIColor.brightRed)错误：无效的表达式\(ANSIColor.reset)")
            print("原因：\(message)")
            print("建议：请检查表达式格式和运算符使用")
            
        case .divisionByZero:
            print("\(ANSIColor.brightRed)错误：除零错误\(ANSIColor.reset)")
            print("建议：除数不能为零")
            
        case .invalidVariableName(let name):
            print("\(ANSIColor.brightRed)错误：无效的变量名 '\(name)'\(ANSIColor.reset)")
            print("变量名必须以字母开头，只能包含字母、数字和下划线")
            
        case .undefinedVariable(let name):
            print("\(ANSIColor.brightRed)错误：未定义的变量 '\(name)'\(ANSIColor.reset)")
            print("请先定义变量或检查变量名拼写")
        }
    }
    
    func showHistory(_ entries: [String]) {
        if entries.isEmpty {
            print("没有历史记录")
            return
        }
        
        print("\(ANSIColor.cyan)计算历史记录:\(ANSIColor.reset)")
        for (index, entry) in entries.enumerated() {
            print("\(index + 1). \(entry)")
        }
    }
    
    func showVariables(_ variables: [String: Double]) {
        if variables.isEmpty {
            print("没有定义的变量")
            return
        }
        
        print("\(ANSIColor.cyan)已定义的变量:\(ANSIColor.reset)")
        for (name, value) in variables.sorted(by: { $0.key < $1.key }) {
            print("\(name) = \(value.formattedString)")
        }
    }
    
    func showHelp() {
        print("""
        \(ANSIColor.cyan)Swift 计算器 v2.0 使用帮助\(ANSIColor.reset)
        
        \(ANSIColor.yellow)基本操作:\(ANSIColor.reset)
          + 加法        - 减法        * 乘法        / 除法        ^ 幂运算
        
        \(ANSIColor.yellow)数学函数:\(ANSIColor.reset)
          sqrt(x)    - 平方根           abs(x)     - 绝对值
          pow(x,y)   - x的y次方         round(x)   - 四舍五入
          log(x)     - 自然对数         log10(x)   - 常用对数
          sin(x)     - 正弦函数         cos(x)     - 余弦函数
          tan(x)     - 正切函数         ceil(x)    - 向上取整
          floor(x)   - 向下取整         factorial(x) - 阶乘
        
        \(ANSIColor.yellow)常量:\(ANSIColor.reset)
          pi         - 圆周率          e          - 自然对数底
          tau        - 2π              golden     - 黄金比例
        
        \(ANSIColor.yellow)变量操作:\(ANSIColor.reset)
          let x = 5  - 定义变量        x          - 使用变量
          vars       - 显示所有变量
        
        \(ANSIColor.yellow)特殊变量:\(ANSIColor.reset)
          ans        - 上一次计算结果
        
        \(ANSIColor.yellow)科学计数法:\(ANSIColor.reset)
          1.5e3      - 1500            2E-4       - 0.0002
        
        \(ANSIColor.yellow)函数绘图:\(ANSIColor.reset)
          draw(y=x^2)     - 绘制二次函数
          draw(y=sin(x))  - 绘制正弦函数
          draw(y=2*x+1)   - 绘制线性函数
        
        \(ANSIColor.yellow)命令:\(ANSIColor.reset)
          help       - 显示帮助        clear      - 清屏
          history    - 显示历史        record     - 保存历史到文件
          vars       - 显示变量        ans        - 显示上次结果
          draw(y=f(x)) - 绘制函数图像  quit       - 退出程序
        
        \(ANSIColor.yellow)快捷键:\(ANSIColor.reset)
          ↑ ↓ 箭头键 - 浏览历史命令    ← → 箭头键 - 移动光标
          Ctrl+C     - 退出程序
        """)
    }
    
    private func showSupportedFunctions() {
        print("支持的函数：sqrt(x), abs(x), pow(x,y), round(x), log(x), log10(x)")
        print("           sin(x), cos(x), tan(x), ceil(x), floor(x), factorial(x)")
    }
    
    func showMessage(_ message: String) {
        print(message)
    }
    
    func showSuccessMessage(_ message: String) {
        print("\(ANSIColor.green)\(message)\(ANSIColor.reset)")
    }
    
    func showWarningMessage(_ message: String) {
        print("\(ANSIColor.yellow)\(message)\(ANSIColor.reset)")
    }
}

// MARK: - Error Highlighter
class ErrorHighlighter {
    static func highlightError(expression: String, position: Int, length: Int = 1) -> String {
        var result = expression + "\n"
        if position < expression.count && position >= 0 {
            result += String(repeating: " ", count: position)
            result += ANSIColor.brightRed + String(repeating: "^", count: max(1, length)) + ANSIColor.reset
        }
        return result
    }
}

// MARK: - Animation Manager
class AnimationManager {
    func showStartupAnimation() {
        let frames = [
            " _____       _ ",
            " _____       _  _____",
            " _____       _  _____ _    _ _            _             "
        ]
        
        print("\u{1B}[2J\u{1B}[H", terminator: "")
        
        for frame in frames {
            print("\u{1B}[2J\u{1B}[H", terminator: "")
            print(frame)
            usleep(300000) // 300ms
        }
        
        usleep(500000) // 500ms
        print("\u{1B}[2J\u{1B}[H", terminator: "")
    }
}