import UIKit
import CoreBluetooth

final class ViewController: UIViewController
{
    @IBOutlet private weak var tableView: UITableView!
    
    private let manager = BTManager.shared
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 44
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] notification in
            self?.manager.reset()
            self?.manager.scan()
        }
        
        manager.onScanDataUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
        
        manager.onErrorOccured = { [weak self] title, error in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func refreshButtonPressed(_ sender: Any)
    {
        manager.reset()
        manager.scan()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return manager.scanData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceTableViewCell") as! DeviceTableViewCell
        cell.configure(device: manager.scanData[indexPath.row].peripheral)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let data = manager.scanData[indexPath.row]
        
        if data.peripheral.state != .disconnected {
            manager.disconnect(peripheral: data.peripheral)
        }
        else {
            manager.connect(data: data)
        }
    }
}


final class DeviceTableViewCell: UITableViewCell
{
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    func configure(device: CBPeripheral)
    {
        nameLabel.text = device.name ?? device.identifier.uuidString
        
        let state: String
        
        switch device.state
        {
        case .connected:
            state = "Connected"
        case .connecting:
            state = "Connecting"
        case .disconnected:
            state = "Disonnected"
        case .disconnecting:
            state = "Disonnecting"
        @unknown default:
            state = "Unknown"
        }
        
        statusLabel.text = state
    }
}
