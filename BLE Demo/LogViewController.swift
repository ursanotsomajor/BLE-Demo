import UIKit

final class LogViewController: UIViewController
{
    private var log = [LoggerEntry]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        Logger.shared.onEntryAdded = { [weak self] in
            self?.update()
        }
        
        update()
    }
    
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    public override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        super.motionBegan(motion, with: event)

        if motion == .motionShake
        {
            Logger.sendViaEmail(vc: self)
        }
    }
    
    func update()
    {
        log = Logger.shared.entries.reversed()
        tableView.reloadData()
    }
}

extension LogViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return log.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogTableViewCell") as! LogTableViewCell
        cell.label.text = log[indexPath.row].string
        return cell
    }
}

final class LogTableViewCell: UITableViewCell
{
    @IBOutlet weak var label: UILabel!
}
