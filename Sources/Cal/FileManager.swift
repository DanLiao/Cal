import Foundation

// MARK: - History Manager
class HistoryManager: ObservableObject {
    private let maxHistorySize: Int
    private var historyEntries: [HistoryEntry] = []
    
    init(maxSize: Int = 50) {
        self.maxHistorySize = maxSize
    }
    
    func addEntry(_ input: String, result: Double) {
        let entry = HistoryEntry(input: input, result: result, timestamp: Date())
        
        if historyEntries.count >= maxHistorySize {
            historyEntries.removeFirst()
        }
        
        historyEntries.append(entry)
        notifyObservers()
    }
    
    func getHistory() -> [HistoryEntry] {
        return historyEntries
    }
    
    func clearHistory() {
        historyEntries.removeAll()
        notifyObservers()
    }
    
    func getFormattedHistory() -> [String] {
        return historyEntries.map { "\($0.input) = \($0.result.formattedString)" }
    }
    
    private func notifyObservers() {
        // Notify observers of history changes
    }
}

// MARK: - History Entry
struct HistoryEntry {
    let input: String
    let result: Double
    let timestamp: Date
    
    var formattedString: String {
        return "\(input) = \(result.formattedString)"
    }
}

// MARK: - File Operations Manager
class FileOperationsManager {
    private let historyManager: HistoryManager
    
    init(historyManager: HistoryManager) {
        self.historyManager = historyManager
    }
    
    func saveHistoryToFile() -> Result<String, FileError> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HH"
        
        guard let recordDir = getRecordDirectory() else {
            return .failure(.directoryCreationFailed("无法确定记录目录"))
        }
        
        // Create directory if it doesn't exist
        if let error = createDirectoryIfNeeded(recordDir) {
            return .failure(error)
        }
        
        var filename = "\(recordDir)/\(dateFormatter.string(from: Date())).txt"
        
        // Add minutes if file exists
        if FileManager.default.fileExists(atPath: filename) {
            dateFormatter.dateFormat = "yyyyMMdd_HHmm"
            filename = "\(recordDir)/\(dateFormatter.string(from: Date())).txt"
        }
        
        let historyText = historyManager.getFormattedHistory().joined(separator: "\n")
        
        do {
            try historyText.write(toFile: filename, atomically: true, encoding: .utf8)
            return .success(filename)
        } catch {
            return .failure(.writeFailed(error.localizedDescription))
        }
    }
    
    private func getRecordDirectory() -> String? {
        // Try environment variable first
        if let appPath = ProcessInfo.processInfo.environment["APP_PATH"] {
            let appDirPath = URL(fileURLWithPath: appPath).deletingLastPathComponent().path
            return "\(appDirPath)/record"
        }
        
        // Try fixed path
        let fixedPath = "/Volumes/M4backup/Cal/record"
        if FileManager.default.fileExists(atPath: fixedPath) {
            return fixedPath
        }
        
        // Use current directory as fallback
        return "record"
    }
    
    private func createDirectoryIfNeeded(_ path: String) -> FileError? {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                return nil
            } catch {
                return .directoryCreationFailed(error.localizedDescription)
            }
        }
        return nil
    }
}

// MARK: - File Error Types
enum FileError: Error, LocalizedError {
    case directoryCreationFailed(String)
    case writeFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let message):
            return "目录创建失败: \(message)"
        case .writeFailed(let message):
            return "文件写入失败: \(message)"
        }
    }
}

// MARK: - Observable Protocol
protocol ObservableObject {
    // Protocol for objects that can be observed for changes
}

// MARK: - Variable Storage Manager
class VariableStorageManager {
    private var variables: [String: Double] = [:]
    
    func setVariable(_ name: String, value: Double) {
        variables[name] = value
    }
    
    func getVariable(_ name: String) -> Double? {
        return variables[name]
    }
    
    func getAllVariables() -> [String: Double] {
        return variables
    }
    
    func clearVariables() {
        variables.removeAll()
    }
    
    func removeVariable(_ name: String) {
        variables.removeValue(forKey: name)
    }
    
    func hasVariable(_ name: String) -> Bool {
        return variables.keys.contains(name)
    }
}