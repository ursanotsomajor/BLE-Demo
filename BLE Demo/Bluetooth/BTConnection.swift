import Foundation
import CoreBluetooth

final class BTConnection: NSObject
{
    var onErrorOccured: ((String, Error) -> Void)?
    
    private let psmID = CBUUID(string: CBUUIDL2CAPPSMCharacteristicString)
    
    let peripheral: CBPeripheral
    
    private let queue = DispatchQueue(label: "BTConnectionQueue",
                                      qos: .userInitiated, attributes: [],
                                      autoreleaseFrequency: .workItem, target: nil)

    private var psmCharacteristic: CBCharacteristic?
    
    private var channel: CBL2CAPChannel?

    private var outputData = Data()
    
    
    init(peripheral: CBPeripheral)
    {
        self.peripheral = peripheral
        
        super.init()
        
        self.peripheral.delegate = self
        
        peripheral.discoverServices(nil)
    }
    
    func send(data: Data)
    {
        queue.sync {
            self.outputData.append(data)
        }
        
        send()
    }
}


extension BTConnection: CBPeripheralDelegate
{
    // MARK: Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if let error = error
        {
            let title = "Service discovery error"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }

        guard let services = peripheral.services, !services.isEmpty else {
            return
        }
        
        Logger.add(title: "Did discover services: \(String(describing: services))")
        
        for service in services
        {
            peripheral.discoverCharacteristics(nil, for: service)
            peripheral.discoverIncludedServices(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?)
    {
        if let error = error
        {
            let title = "Included service discovery error for service: \(String(describing: service))"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }
        
        guard let services = service.includedServices, !services.isEmpty else {
            return
        }
        
        Logger.add(title: "Did discover included services: \(String(describing: services))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService])
    {
        Logger.add(title: "Did modify services: \(String(describing: peripheral.services))")
    }
    
    
    // MARK: Characteristics
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        if let error = error
        {
            let title = "Characteristic discovery error for service: \(String(describing: service))"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }
        
        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            return
        }
        
        Logger.add(title: "Did discover characteristics \(String(describing: characteristics))")

        for characteristic in characteristics
        {
            peripheral.discoverDescriptors(for: characteristic)
            
//            peripheral.readValue(for: characteristic)
            
//            if characteristic.uuid == psmID
//            {
//                psmCharacteristic = characteristic
//                peripheral.setNotifyValue(true, for: characteristic)
//                peripheral.readValue(for: characteristic)
//            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if let error = error
        {
            let title = "Value update error for characteristic: \(String(describing: characteristic))"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }
        
        if let value = characteristic.value, let str = String(data: value, encoding: .utf8)
        {
//            let byteArray = [UInt8](value)
//
//            let stringValue = String(data: value, encoding: .ascii)
//
//            let intValue = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
//                return ptr.pointee
//            }
//
//            let floatValue = value.withUnsafeBytes { (ptr: UnsafePointer<Float>) -> Float in
//                return ptr.pointee
//            }
            
            Logger.add(title: "Updated value for characteristic: \(str)")
        }

//        if let dataValue = characteristic.value
//        {
        
//            let psm = dataValue.uint16
//            peripheral.openL2CAPChannel(psm)
//
//            Logger.add(title: "Opening PSM channel: \(psm)")
//        }
//        else
//        {
//            Logger.add(title: "Problem decoding PSM")
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    {
        if let error = error
        {
            let title = "Failed to update notification state on characteristic: \(String(describing: characteristic))"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }
        
        Logger.add(title: "Updated notification state to '\(characteristic.isNotifying)' on characteristic: \(characteristic)")
    }
    
    
    // MARK: Descritors
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        if let error = error
        {
            let title = "Descriptor discovery error for characteristic: \(String(describing: characteristic))"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }
        
        guard let descriptors = characteristic.descriptors, !descriptors.isEmpty else {
            return
        }
        
        Logger.add(title: "Did discover descriptors: \(String(describing: descriptors))")
        
        for descriptor in descriptors
        {
            Logger.add(title: String(describing: descriptor.value))
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    {
        if let error = error
        {
            let title = "Update value error for descriptor: \(String(describing: descriptor))"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }
        
        Logger.add(title: "Did update value for descriptor: \(String(describing: descriptor))")
    }
    

    // MARK: L2Cap
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        if let error = error
        {
            let title = "L2Cap channel opening error"
            onErrorOccured?(title, error)
            Logger.add(title: title, error: error)
            return
        }
        
        guard let channel = channel else {
            return
        }
        
        Logger.add(title: "L2Cap channel opened. Peripheral: \(peripheral)")
        
        self.channel = channel
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.outputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
    }
}


extension BTConnection: StreamDelegate
{
    func stream(_ aStream: Stream, handle eventCode: Stream.Event)
    {
        switch eventCode
        {
        case .openCompleted:
            Logger.add(title: "Stream opened")
            
        case .endEncountered:
            Logger.add(title: "Stream end encountered")
            
        case .hasBytesAvailable:
            Logger.add(title: "Bytes are available")
            readBytes(from: aStream as! InputStream)
            
        case .hasSpaceAvailable:
            Logger.add(title: "Space is available")
            send()
            
        case .errorOccurred:
            Logger.add(title: "Stream error occured")
            
        default:
            Logger.add(title: "Unknown stream event")
        }
    }
    
    private func send()
    {
        guard let ostream = channel?.outputStream, !outputData.isEmpty, ostream.hasSpaceAvailable else {
            return
        }
        
        let bytesWritten = ostream.write(outputData)
        
        print("bytesWritten = \(bytesWritten)")
        
        queue.sync {
            if bytesWritten < outputData.count {
                outputData = outputData.advanced(by: bytesWritten)
            }
            else {
                outputData.removeAll()
            }
        }
    }
    
    private func readBytes(from stream: InputStream)
    {
        let bufLength = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufLength)
        
        defer {
            buffer.deallocate()
        }
        
        let bytesRead = stream.read(buffer, maxLength: bufLength)
        var returnData = Data()
        returnData.append(buffer, count:bytesRead)
        
        if stream.hasBytesAvailable {
            readBytes(from: stream)
        }
    }
}
