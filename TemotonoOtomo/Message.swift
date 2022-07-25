//
//  Message.swift
//  TemotonoOtomo
//
//  Created by Shun on 2022/07/25.
//

import Foundation

class Message{
    var sendCount: UInt = 0
    var receivedCount: UInt = 0
    var image: Data
    
    init(image: Data, sendCount: UInt, receivedCount: UInt) {
        self.image = image
        self.sendCount = sendCount
        self.receivedCount = receivedCount
    }
    
    init(data: Data) {
        sendCount = Data(data[0...7]).withUnsafeBytes{ $0.load(as: UInt.self) }
        receivedCount = Data(data[8...15]).withUnsafeBytes { $0.load(as: UInt.self) }
        image = data[16...]
    }
    
    func toData() -> Data {
        var data = Data(bytes: &sendCount, count: MemoryLayout.size(ofValue: sendCount))
        data.append(Data(bytes: &receivedCount, count: MemoryLayout.size(ofValue: receivedCount)))
        data.append(image)
        
        return data
    }
    
}

//var dummyImageData: Data = "aaaaaaaaaaaaaaaaaaaaaz".data(using: String.Encoding.utf8)!
//
//var test = Message(image: dummyImageData, sendCount: 10000000, receivedCount: 2)
//var data = test.toData()
//
//var result = Message(data: data)
