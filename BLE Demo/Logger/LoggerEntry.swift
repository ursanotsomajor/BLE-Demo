import Foundation

struct LoggerEntry: Codable
{
    var date = Date()
    
    let title: String
    let message: String?
    
    let emphasize: Bool
    
    init(title: String, message: String? = nil, emphasize: Bool = false)
    {
        self.title = title
        self.message = message
        self.emphasize = emphasize
    }
    
    var string: String
    {
        var result = "[\(date)] \(title)"
        if let mess = message { result += "\n\(mess)" }
        return emphasize ? "\n•••\n\(result)\n•••\n" : result
    }
}
