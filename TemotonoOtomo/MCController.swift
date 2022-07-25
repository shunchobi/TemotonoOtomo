//
//  MCController.swift
//  TemotonoOtomo
//
//  Created by Shun on 2022/07/07.
//

import Foundation
import MultipeerConnectivity
import os

class ArrayManager{
    // array generate, func add, func delete, func get
    var array: [Any?]
    
    init(){
        array = []
    }
    
    func addToLast(_ contant: Any){
        array.append(contant)
    }
    
    func getLast() -> Any? {
        if let lastContent = array.last{
            array.removeLast()
            if array.count >= 100 {
                array.removeAll(keepingCapacity: true)
            }
            return lastContent
        }
        return nil
    }
    
    func getCount() -> Int{
        return array.count
    }
    
    func removeAll(){
        array.removeAll(keepingCapacity: true)
    }
}

class DataController{
    // func get data, func data to UIImage -> UIImage,
    private let array: ArrayManager
    
    init(){
        array = ArrayManager()
    }
    
    func addData(_ data: Data){
        array.addToLast(data)
    }
    
    func getData() -> Data?{
        if let targetData = array.getLast(){
            return targetData as? Data
        }
        return nil
    }

    
    func getImage() -> UIImage?{
        if let data = getData(){
            let UIImage = UIImage(data: data)
            return UIImage
        }
        return nil
    }
    
    func getArrayCount() -> Int{
        return array.getCount()
    }
    
    func removeAllArrayContents(){
        array.removeAll()
    }
}

// DataController.getImage()





class MPCSession: NSObject, ObservableObject, StreamDelegate {
    private let serviceType = "example-color"

    private let session: MCSession
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let log = Logger()

    @Published var connectedPeers: [MCPeerID] = []
    @Published var currentScreenImage: UIImage? = nil
    
    var dataController: DataController
    
    
//    @Published var sendCount = 0
//    @Published var recivedCoount = 0
//    @Published var dataArrayCount = 0
//    @Published var streamCountNum = 0



    override init() {
//        precondition(Thread.isMainThread)
        session = MCSession(peer: myPeerId) // 接続を開く
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType) // 探してもらう
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType) // 探す
        dataController = DataController()
        super.init()

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }

    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }

    ///
    /// Advertiser はViewからここで入力値を受け取る
    ///
    func send(imageData: Data) { // Data
        do {
            try session.send(imageData, toPeers: session.connectedPeers, with: .unreliable)
            Counter.sentCont += 1
        } catch {
            log.error("Error for sending: \(String(describing: error))")
        }
    }
}


////
/// Advertiver
///
extension MPCSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        precondition(Thread.isMainThread)
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        precondition(Thread.isMainThread)
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}


////
/// Browser
///
extension MPCSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}


////
/// Session
///
extension MPCSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.debugDescription)")
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }
    
    ///
    /// startStream メソッドから送られてきたDataをここで受け取る
    ///
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("recived streamName data")
        stream.delegate = self
        stream.schedule(in: .main, forMode: RunLoop.Mode.default)
        stream.open()
        
//        DispatchQueue.main.sync {
//            self.streamCountNum = Int(streamName) ?? 777
//        }
        
//        print("recived streamName data")
//        if let imageData = Data(base64Encoded: streamName, options: []) {
//            print("success encode streanName to data")
//            let image = UIImage(data: imageData, scale: 0.1) // --> これを表示する
//            self.currentScreenImage = image
//        }

//        var data:Data?
//        let bufferSize = 1024
//        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
//        while stream.hasBytesAvailable {
//            let read = stream.read(buffer, maxLength: bufferSize)
//            data?.append(buffer, count: read)
//        }
//        buffer.deallocate()

    }

    ///
    /// send メソッドから送られてきたDataをここで受け取る
    ///
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
//        DispatchQueue(label: "net.sambaiz.concurrent_dispatch_queue", attributes: .concurrent).async {}
        
//        self.dataController.addData(data)
        DispatchQueue.main.async {
            
            let message = Message(data: data)
            let imageData = message.image
            let partnersRecivedCount = message.receivedCount
            Counter.partnersRecivedCount = Int(partnersRecivedCount)
            Counter.delta = abs(Counter.sentCont - Counter.partnersRecivedCount)
            Counter.recivedCount += 1
            
            if let image = UIImage(data: imageData){
                
//            if let image = self.dataController.getImage() {
//                self.dataController.removeAllArrayContents()
//                DispatchQueue.main.sync {
                    self.currentScreenImage = image
                
                    
//                    self.dataArrayCount = self.dataController.getArrayCount()
                }
            }
    
        

        
//        DispatchQueue.global().async { // 3分で1039回送信
//            if let image = UIImage(data: data){
//                DispatchQueue.main.sync {
//                    self.currentScreenImage = image
//                    self.recivedCoount += 1
//                    Communicater.sent = false
//                }
//            }
//        }
//
//            DispatchQueue.main.async {　// 3分で927回送信
//                if let image = UIImage(data: data){
//                    self.currentScreenImage = image
//                    self.recivedCoount += 1
//                    Communicater.sent = false
//            }
//        }
    }
        
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//
//        // data -> UIImage
//        // UIImage(data: data)!
//        if let image = UIImage(data: data) {
//            log.info("didReceive color \(image)")
//            DispatchQueue.main.async {
//                /// browser はここでデータを受け取る
//                self.currentScreenImage = image
//            }
//        } else {
//            log.info("didReceive invalid value \(data.count) bytes")
//        }
//    }
  


    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}



extension MCSessionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notConnected:
            return "notConnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        @unknown default:
            return "\(rawValue)"
        }
    }
}
