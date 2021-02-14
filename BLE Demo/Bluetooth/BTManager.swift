import Foundation
import CoreBluetooth

typealias BTScanData = (peripheral: CBPeripheral, advData: [String : Any])

final class BTManager: NSObject
{
    var onScanDataUpdated: (() -> Void)?
    var onErrorOccured: ((String, Error) -> Void)?
    
    static let shared = BTManager()
    
    private let centralManager = CBCentralManager()
    
    private(set) var scanData = [BTScanData]() {
        didSet {
            onScanDataUpdated?()
        }
    }
    
    private(set) var connections = Set<BTConnection>()
    
    
    override init()
    {
        super.init()
        
        centralManager.delegate = self
    }

    func reset()
    {
        for conn in connections
        {
            disconnect(peripheral: conn.peripheral)
        }
        
        scanData.removeAll()
    }
    
    func scan()
    {
        guard centralManager.state == .poweredOn else {
            return
        }

        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        centralManager.scanForPeripherals(withServices: nil, options: options)
    }
    
    func connect(data: BTScanData)
    {
        DispatchQueue.main.async
        {
            self.centralManager.stopScan()
            self.centralManager.connect(data.peripheral, options: nil)

            self.updatePeripheralState(data.peripheral)
            
            Logger.add(title: "Connecting peripheral: \(data.peripheral.description), \n Advertisement data: \(data.advData)", emphasize: true)
        }
    }
    
    func disconnect(peripheral: CBPeripheral)
    {
        Logger.add(title: "Disconnecting peripheral: \(peripheral.description)", emphasize: true)
        
        centralManager.cancelPeripheralConnection(peripheral)
        updatePeripheralState(peripheral)
        
        if let index = connections.firstIndex(where: { $0.peripheral == peripheral })
        {
            connections.remove(at: index)
        }
    }
    
    // Update peripheral object in scanData list to update UI
    func updatePeripheralState(_ peripheral: CBPeripheral)
    {
        if let index = scanData.firstIndex(where: { $0.peripheral == peripheral })
        {
            scanData[index] = (peripheral, scanData[index].1)
        }
    }
}

extension BTManager: CBCentralManagerDelegate
{
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        let message: String
        
        switch central.state
        {
        case .poweredOff:
            // Alert telling user to turn BT on
            message = "poweredOff"
            
        case .poweredOn:
            scan()
            message = "poweredOn"
            
        case .resetting:
            message = "resetting"
            
        case .unauthorized:
            // Alert user to give the app needed permissions
            message = "unauthorized"
            
        case .unsupported:
            message = "unsupported"
            
        case .unknown:
            message = "unknown"
            
        @unknown default:
            message = "unknown"
        }
        
        Logger.add(title: "Did update state: \(message)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        Logger.add(title: "Did discover a peripheral: \(peripheral), RSSI: \(RSSI)")
        
        if !scanData.contains(where: { $0.peripheral.identifier == peripheral.identifier })
        {
            scanData.append((peripheral, advertisementData))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        Logger.add(title: "Did connect to peripheral: \(peripheral)")
        
        let conn = BTConnection(peripheral: peripheral)
        
        conn.onErrorOccured = { [weak self] title, error in
            let text = "Peripheral error: " + title
            self?.onErrorOccured?(text, error)
        }
        
        connections.insert(conn)
        
        updatePeripheralState(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        Logger.add(title: "Did fail to connect to peripheral: \(peripheral)", error: error)
        
        if let e = error {
            onErrorOccured?("Did fail to connect", e)
        }
        
        updatePeripheralState(peripheral)
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        if let e = error {
            onErrorOccured?("Disconnected: \(peripheral)", e)
        }
        else {
            Logger.add(title: "Did disconnect peripheral: \(peripheral)")
        }
        
        updatePeripheralState(peripheral)
    }
    
    
    func centralManager(_ central: CBCentralManager,
                        didUpdateANCSAuthorizationFor peripheral: CBPeripheral)
    {
        Logger.add(title: "Did update ANCS auth for peripheral: \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any])
    {
        Logger.add(title: "Will restore state: \(dict.description)")
    }
    
    func centralManager(_ central: CBCentralManager,
                        connectionEventDidOccur event: CBConnectionEvent,
                        for peripheral: CBPeripheral)
    {
        Logger.add(title: "Connection event '\(event)' did occur for peripheral: \(peripheral)")
    }
}


