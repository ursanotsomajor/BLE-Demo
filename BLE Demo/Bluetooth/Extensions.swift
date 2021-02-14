import Foundation
import CoreBluetooth

extension UInt16
{
    var data: Data
    {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension Data
{
    var uint16: UInt16
    {
        return withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}

extension OutputStream
{
    func write(_ data: Data) -> Int
    {
        return data.withUnsafeBytes({ (rawBufferPointer: UnsafeRawBufferPointer) -> Int in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            return self.write(bufferPointer.baseAddress!, maxLength: data.count)
        })
    }
}

extension CBCharacteristic
{
    var isReadable: Bool
    {
        (properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0
    }
    
    var isWritable: Bool
    {
        let raw = properties.rawValue;

        let isWriteableWithResponse = (raw & CBCharacteristicProperties.write.rawValue) != 0
        
        let isWriteableWithoutResponse = (raw & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0
        
        return isWriteableWithResponse || isWriteableWithoutResponse
    }
    
    var isNotifiable: Bool
    {
        return (properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0
    }
}
