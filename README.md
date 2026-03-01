# Cal — Swift 命令行计算器

一个用 Swift 编写的命令行计算器，支持变量、科学函数、函数绘图和历史记录。

## 安装

### 下载预编译二进制（推荐）

在 [Releases](https://github.com/DanLiao/Cal/releases) 页面下载最新版 `Cal`，然后：

```bash
chmod +x Cal
./Cal
```

> 要求：macOS 11+（Apple Silicon / Intel 均支持）

### 从源码编译

```bash
git clone https://github.com/DanLiao/Cal.git
cd Cal
swift build -c release
.build/release/Cal
```

## 使用示例

```
>> 2 + 3 * 4          # 基本运算       → 14
>> sqrt(16)           # 数学函数       → 4.0
>> sin(pi / 2)        # 三角函数       → 1.0
>> factorial(10)      # 阶乘           → 3628800.0
>> let x = 5          # 定义变量       → 5.0
>> x^2 + 1            # 使用变量       → 26.0
>> ans * 2            # 使用上次结果   → 52.0
>> draw(y=sin(x))     # 绘制函数图像
```

## 支持的功能

### 运算符

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `+` `-` `*` `/` | 四则运算 | `10 / 3` |
| `^` | 幂运算 | `2^10` → 1024 |
| `(` `)` | 括号 | `(2 + 3) * 4` |

### 数学函数

| 函数 | 说明 |
|------|------|
| `sqrt(x)` | 平方根 |
| `abs(x)` | 绝对值 |
| `pow(x, y)` | x 的 y 次方 |
| `log(x)` | 自然对数 |
| `log10(x)` `log2(x)` | 常用对数 / 二进制对数 |
| `exp(x)` | e 的 x 次方 |
| `sin(x)` `cos(x)` `tan(x)` | 三角函数（弧度） |
| `asin(x)` `acos(x)` `atan(x)` | 反三角函数 |
| `atan2(y, x)` | 两参数反正切 |
| `round(x)` `ceil(x)` `floor(x)` | 舍入函数 |
| `min(x, y)` `max(x, y)` | 最值 |
| `factorial(x)` | 阶乘（整数，最大 20） |

### 数学常量

| 常量 | 值 |
|------|----|
| `pi` | 3.14159265358979… |
| `e` | 2.71828182845904… |
| `tau` | 2π |
| `golden` | 黄金比例 1.61803… |

### 变量系统

```
>> let x = 10
>> let y = x * 2
>> vars               # 列出所有变量
>> ans                # 查看上次结果
```

### 函数绘图

使用 `draw(y=表达式)` 在终端绘制 ASCII 函数图像，自动适配终端尺寸：

```
>> draw(y=x^2)
>> draw(y=sin(x))
>> draw(y=log(x))
>> draw(y=2*x+1)
```

### 命令

| 命令 | 说明 |
|------|------|
| `help` / `h` / `?` | 显示帮助 |
| `clear` / `cls` | 清屏 |
| `history` | 查看计算历史 |
| `record` | 保存历史到文件（`record/` 目录） |
| `vars` / `variables` | 查看所有变量 |
| `ans` | 查看上次结果 |
| `quit` / `exit` / `q` | 退出 |

方向键 ↑ ↓ 可浏览历史命令，← → 可移动光标。

## 项目结构

```
Cal/
├── Sources/Cal/
│   ├── main.swift              # 程序入口、终端输入、历史导航
│   ├── Calculator.swift        # 计算引擎、表达式解析、函数绘图
│   ├── ExpressionBridge.swift  # Expression 库桥接（解决命名冲突）
│   ├── CommandProcessor.swift  # 命令解析与执行（命令模式）
│   ├── UI.swift                # 终端界面输出
│   ├── FileManager.swift       # 历史记录持久化
│   └── Extensions.swift        # 工具扩展
├── Tests/CalTests/
│   └── CalculatorTests.swift   # 单元测试
├── Package.swift               # Swift Package Manager 配置
└── record/                     # 历史记录保存目录
```

## 技术细节

- **表达式求值**：使用 [nicklockwood/Expression](https://github.com/nicklockwood/Expression) 库，替代 `NSExpression`，支持更多函数和运算符
- **命名冲突解决**：`ExpressionBridge.swift` 仅 `import Expression`（不导入 Foundation），通过类型别名（`CalcExpression` 等）暴露给全模块，规避 macOS 15 引入的 `Foundation.Expression` 冲突
- **设计模式**：命令模式（`Command`）、策略模式（`MathFunctionStrategy`）
- **终端适配**：通过 `ioctl(TIOCGWINSZ)` 自动检测终端尺寸，绘图自动缩放

## 运行测试

```bash
swift test
```

## 许可证

MIT License
