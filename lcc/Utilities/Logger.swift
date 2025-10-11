import Foundation
import OSLog

/// 📝 Structured Logging
///
/// **Use instead of print() or NSLog():**
/// ```swift
/// let logger = Logger(category: .networking)
/// logger.info("API call succeeded")
/// logger.error("API call failed", error: error)
/// ```
///
/// **Built-in loggers:**
/// ```swift
/// Logger.app.info("App launched")
/// Logger.networking.error("Network failed")
/// Logger.ui.debug("Button tapped")
/// ```
///
/// **Benefits:**
/// - Viewable in Console.app (filter by subsystem)
/// - Debug logs auto-disabled in production
/// - Proper log levels (debug, info, warning, error, fault)
/// - Includes file, function, line automatically
struct Logger {
    
    /// Log categories for different subsystems
    enum Category: String {
        case app = "app"
        case networking = "networking"
        case ui = "ui"
        case performance = "performance"
        case imageLoading = "imageLoading"
        case metrics = "metrics"
    }
    
    /// Log levels
    enum Level {
        case debug
        case info
        case warning
        case error
        case fault
    }
    
    private let logger: os.Logger
    private let category: Category
    
    init(category: Category) {
        self.category = category
        self.logger = os.Logger(subsystem: AppEnvironment.bundleIdentifier, category: category.rawValue)
    }
    
    // MARK: - Logging Methods
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppEnvironment.debugLoggingEnabled else { return }
        let context = formatContext(file: file, function: function, line: line)
        logger.debug("[\(context)] \(message)")
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.info("[\(context)] \(message)")
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.warning("[\(context)] ⚠️ \(message)")
    }
    
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        if let error = error {
            logger.error("[\(context)] ❌ \(message) - Error: \(error.localizedDescription)")
        } else {
            logger.error("[\(context)] ❌ \(message)")
        }
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.fault("[\(context)] 🔥 \(message)")
    }
    
    // MARK: - Helpers
    
    private func formatContext(file: String, function: String, line: Int) -> String {
        let filename = (file as NSString).lastPathComponent
        return "\(filename):\(line)"
    }
    
    // MARK: - Static Convenience Loggers
    
    static let app = Logger(category: .app)
    static let networking = Logger(category: .networking)
    static let ui = Logger(category: .ui)
    static let performance = Logger(category: .performance)
    static let imageLoading = Logger(category: .imageLoading)
    static let metrics = Logger(category: .metrics)
}

// MARK: - Legacy Compatibility

/// Bridge for migrating from NSLog/print to structured logging
func log(_ message: String, category: Logger.Category = .app, level: Logger.Level = .info) {
    let logger = Logger(category: category)
    switch level {
    case .debug:
        logger.debug(message)
    case .info:
        logger.info(message)
    case .warning:
        logger.warning(message)
    case .error:
        logger.error(message)
    case .fault:
        logger.fault(message)
    }
}

