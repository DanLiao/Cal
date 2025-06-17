import XCTest
@testable import Cal

final class CalculatorTests: XCTestCase {
    var calculator: CalculatorEngine!
    
    override func setUp() {
        super.setUp()
        calculator = CalculatorEngine()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    // MARK: - Basic Operations Tests
    func testBasicAddition() throws {
        let result = try calculator.evaluate("2 + 3")
        XCTAssertEqual(result, 5.0, accuracy: 0.0001)
    }
    
    func testBasicSubtraction() throws {
        let result = try calculator.evaluate("10 - 4")
        XCTAssertEqual(result, 6.0, accuracy: 0.0001)
    }
    
    func testBasicMultiplication() throws {
        let result = try calculator.evaluate("3 * 4")
        XCTAssertEqual(result, 12.0, accuracy: 0.0001)
    }
    
    func testBasicDivision() throws {
        let result = try calculator.evaluate("15 / 3")
        XCTAssertEqual(result, 5.0, accuracy: 0.0001)
    }
    
    func testDivisionByZero() {
        XCTAssertThrowsError(try calculator.evaluate("5 / 0")) { error in
            XCTAssertTrue(error is CalculatorError)
            if case .divisionByZero = error as? CalculatorError {
                // Expected error type
            } else {
                XCTFail("Expected divisionByZero error")
            }
        }
    }
    
    // MARK: - Mathematical Functions Tests
    func testSqrtFunction() throws {
        let result = try calculator.evaluate("sqrt(16)")
        XCTAssertEqual(result, 4.0, accuracy: 0.0001)
    }
    
    func testAbsFunction() throws {
        let negativeResult = try calculator.evaluate("abs(-5)")
        XCTAssertEqual(negativeResult, 5.0, accuracy: 0.0001)
        
        let positiveResult = try calculator.evaluate("abs(5)")
        XCTAssertEqual(positiveResult, 5.0, accuracy: 0.0001)
    }
    
    func testPowFunction() throws {
        let result = try calculator.evaluate("pow(2,3)")
        XCTAssertEqual(result, 8.0, accuracy: 0.0001)
    }
    
    func testTrigonometricFunctions() throws {
        let sinResult = try calculator.evaluate("sin(0)")
        XCTAssertEqual(sinResult, 0.0, accuracy: 0.0001)
        
        let cosResult = try calculator.evaluate("cos(0)")
        XCTAssertEqual(cosResult, 1.0, accuracy: 0.0001)
        
        let tanResult = try calculator.evaluate("tan(0)")
        XCTAssertEqual(tanResult, 0.0, accuracy: 0.0001)
    }
    
    func testLogFunctions() throws {
        let logResult = try calculator.evaluate("log(e)")
        XCTAssertEqual(logResult, 1.0, accuracy: 0.0001)
        
        let log10Result = try calculator.evaluate("log10(100)")
        XCTAssertEqual(log10Result, 2.0, accuracy: 0.0001)
    }
    
    func testRoundingFunctions() throws {
        let roundResult = try calculator.evaluate("round(3.7)")
        XCTAssertEqual(roundResult, 4.0, accuracy: 0.0001)
        
        let ceilResult = try calculator.evaluate("ceil(3.1)")
        XCTAssertEqual(ceilResult, 4.0, accuracy: 0.0001)
        
        let floorResult = try calculator.evaluate("floor(3.9)")
        XCTAssertEqual(floorResult, 3.0, accuracy: 0.0001)
    }
    
    func testFactorialFunction() throws {
        let result = try calculator.evaluate("factorial(5)")
        XCTAssertEqual(result, 120.0, accuracy: 0.0001)
        
        let zeroFactorial = try calculator.evaluate("factorial(0)")
        XCTAssertEqual(zeroFactorial, 1.0, accuracy: 0.0001)
    }
    
    // MARK: - Constants Tests
    func testConstants() throws {
        let piResult = try calculator.evaluate("pi")
        XCTAssertEqual(piResult, Double.pi, accuracy: 0.0001)
        
        let eResult = try calculator.evaluate("e")
        XCTAssertEqual(eResult, M_E, accuracy: 0.0001)
        
        let tauResult = try calculator.evaluate("tau")
        XCTAssertEqual(tauResult, 2 * Double.pi, accuracy: 0.0001)
    }
    
    // MARK: - Variable Tests
    func testVariableAssignment() throws {
        let result = try calculator.evaluate("let x = 5")
        XCTAssertEqual(result, 5.0, accuracy: 0.0001)
        
        let variables = calculator.getVariables()
        XCTAssertEqual(variables["x"], 5.0)
    }
    
    func testVariableUsage() throws {
        _ = try calculator.evaluate("let x = 10")
        let result = try calculator.evaluate("x * 2")
        XCTAssertEqual(result, 20.0, accuracy: 0.0001)
    }
    
    func testComplexVariableExpression() throws {
        _ = try calculator.evaluate("let x = 5")
        _ = try calculator.evaluate("let y = 3")
        let result = try calculator.evaluate("x + y * 2")
        XCTAssertEqual(result, 11.0, accuracy: 0.0001)
    }
    
    // MARK: - Scientific Notation Tests
    func testScientificNotation() throws {
        let result1 = try calculator.evaluate("1.5e3")
        XCTAssertEqual(result1, 1500.0, accuracy: 0.0001)
        
        let result2 = try calculator.evaluate("2E-4")
        XCTAssertEqual(result2, 0.0002, accuracy: 0.000001)
    }
    
    // MARK: - Previous Answer Tests
    func testPreviousAnswer() throws {
        _ = try calculator.evaluate("2 + 3")
        let result = try calculator.evaluate("ans * 2")
        XCTAssertEqual(result, 10.0, accuracy: 0.0001)
    }
    
    // MARK: - Complex Expressions Tests
    func testComplexExpression() throws {
        let result = try calculator.evaluate("(2 + 3) * 4 - 1")
        XCTAssertEqual(result, 19.0, accuracy: 0.0001)
    }
    
    func testNestedFunctions() throws {
        let result = try calculator.evaluate("sqrt(pow(3,2) + pow(4,2))")
        XCTAssertEqual(result, 5.0, accuracy: 0.0001)
    }
    
    // MARK: - Error Handling Tests
    func testEmptyExpression() {
        XCTAssertThrowsError(try calculator.evaluate("")) { error in
            XCTAssertTrue(error is CalculatorError)
            if case .emptyExpression = error as? CalculatorError {
                // Expected error type
            } else {
                XCTFail("Expected emptyExpression error")
            }
        }
    }
    
    func testInvalidCharacter() {
        XCTAssertThrowsError(try calculator.evaluate("2 + $")) { error in
            XCTAssertTrue(error is CalculatorError)
        }
    }
    
    func testMissingParenthesis() {
        XCTAssertThrowsError(try calculator.evaluate("(2 + 3")) { error in
            XCTAssertTrue(error is CalculatorError)
        }
    }
    
    func testInvalidVariableName() {
        XCTAssertThrowsError(try calculator.evaluate("let 123 = 5")) { error in
            XCTAssertTrue(error is CalculatorError)
        }
    }
}

// MARK: - Extension Tests
final class ExtensionTests: XCTestCase {
    func testStringExtensions() {
        let testString = "  hello world  "
        XCTAssertEqual(testString.trimmed, "hello world")
        
        let indexString = "abcdef"
        XCTAssertEqual(indexString.distance(to: indexString.index(indexString.startIndex, offsetBy: 3)), 3)
    }
    
    func testDoubleExtensions() {
        XCTAssertTrue(5.0.isInteger)
        XCTAssertFalse(5.5.isInteger)
        
        XCTAssertEqual(5.0.formattedString, "5")
        XCTAssertEqual(5.5.formattedString, "5.5")
        
        XCTAssertEqual(3.14159.rounded(toPlaces: 2), 3.14, accuracy: 0.001)
    }
    
    func testInputValidator() {
        XCTAssertTrue(InputValidator.containsOnlyValidCharacters("2 + 3"))
        XCTAssertFalse(InputValidator.containsOnlyValidCharacters("2 + $"))
        
        let invalidResult = InputValidator.findInvalidCharacter(in: "2 + $")
        XCTAssertNotNil(invalidResult)
        XCTAssertEqual(invalidResult?.character, "$")
    }
}

// MARK: - History Manager Tests
final class HistoryManagerTests: XCTestCase {
    var historyManager: HistoryManager!
    
    override func setUp() {
        super.setUp()
        historyManager = HistoryManager(maxSize: 3)
    }
    
    override func tearDown() {
        historyManager = nil
        super.tearDown()
    }
    
    func testAddEntry() {
        historyManager.addEntry("2 + 3", result: 5.0)
        let history = historyManager.getHistory()
        
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.input, "2 + 3")
        XCTAssertEqual(history.first?.result, 5.0)
    }
    
    func testMaxSizeLimit() {
        historyManager.addEntry("1", result: 1.0)
        historyManager.addEntry("2", result: 2.0)
        historyManager.addEntry("3", result: 3.0)
        historyManager.addEntry("4", result: 4.0)
        
        let history = historyManager.getHistory()
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history.first?.input, "2")
        XCTAssertEqual(history.last?.input, "4")
    }
    
    func testClearHistory() {
        historyManager.addEntry("2 + 3", result: 5.0)
        historyManager.clearHistory()
        
        let history = historyManager.getHistory()
        XCTAssertTrue(history.isEmpty)
    }
    
    func testFormattedHistory() {
        historyManager.addEntry("2 + 3", result: 5.0)
        historyManager.addEntry("10 / 2", result: 5.0)
        
        let formatted = historyManager.getFormattedHistory()
        XCTAssertEqual(formatted.count, 2)
        XCTAssertEqual(formatted.first, "2 + 3 = 5")
        XCTAssertEqual(formatted.last, "10 / 2 = 5")
    }
}

// MARK: - Variable Storage Tests
final class VariableStorageTests: XCTestCase {
    var variableManager: VariableStorageManager!
    
    override func setUp() {
        super.setUp()
        variableManager = VariableStorageManager()
    }
    
    override func tearDown() {
        variableManager = nil
        super.tearDown()
    }
    
    func testSetAndGetVariable() {
        variableManager.setVariable("x", value: 10.0)
        XCTAssertEqual(variableManager.getVariable("x"), 10.0)
    }
    
    func testUndefinedVariable() {
        XCTAssertNil(variableManager.getVariable("undefined"))
    }
    
    func testHasVariable() {
        variableManager.setVariable("x", value: 5.0)
        XCTAssertTrue(variableManager.hasVariable("x"))
        XCTAssertFalse(variableManager.hasVariable("y"))
    }
    
    func testRemoveVariable() {
        variableManager.setVariable("x", value: 5.0)
        variableManager.removeVariable("x")
        XCTAssertNil(variableManager.getVariable("x"))
    }
    
    func testClearVariables() {
        variableManager.setVariable("x", value: 1.0)
        variableManager.setVariable("y", value: 2.0)
        variableManager.clearVariables()
        
        XCTAssertTrue(variableManager.getAllVariables().isEmpty)
    }
}