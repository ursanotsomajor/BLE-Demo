import Foundation

final class Logger: NSObject
{
    var onEntryAdded: (() -> Void)?
    
    static let shared = Logger()
    
    var entries = [LoggerEntry]()
    
    private var consoleOutput = true
    
    
    func add(entry: LoggerEntry)
    {
        entries.append(entry)
        
        if consoleOutput
        {
            print("\(entry.string)\n")
        }
        
        onEntryAdded?()
    }
    
    class func add(title: String, message: String? = nil, emphasize: Bool = false)
    {
        let entry = LoggerEntry(title: title, message: message, emphasize: emphasize)
        Logger.shared.add(entry: entry)
    }
    
    class func add(entry: LoggerEntry)
    {
        Logger.shared.add(entry: entry)
    }
    
    class func add(title: String, error: Error?)
    {
        var emphasize = false
        var errorMessage: String?
        
        if let err = error {
            emphasize = true
            errorMessage = "Error: " + String(describing: err)
        }
        
        let entry = LoggerEntry(title: title, message: errorMessage, emphasize: emphasize)
        Logger.shared.add(entry: entry)
    }
    
    class func add<T: Hashable>(params: T...)
    {
        for param: T in params
        {
            print(param)
        }
    }
}
