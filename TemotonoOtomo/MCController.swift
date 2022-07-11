//
//  MCController.swift
//  TemotonoOtomo
//
//  Created by Shun on 2022/07/07.
//

import Foundation
import MultipeerConnectivity
import os



class MPCSession: NSObject, ObservableObject, StreamDelegate {
    private let serviceType = "example-color"

    private let session: MCSession
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let log = Logger()

    @Published var connectedPeers: [MCPeerID] = []
    
    // test Date proparty
    @Published var currentScreenImage: UIImage? = nil

    override init() {
        precondition(Thread.isMainThread)
        self.session = MCSession(peer: myPeerId)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

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
    func send(screenImage: UIImage) {
        precondition(Thread.isMainThread)
//        log.info("sendColor: \(String(describing: date)) to \(self.session.connectedPeers.count) peers")
//        self.currentColor = date
        
//        self.currentScreenImage = screenImage
        
        // UIImage -> png
//        image.pngData()
        // UIImage -> jpeg
        // compressionQualityには0~1の範囲で圧縮率を指定する
//        image.jpegData(compressionQuality: 1)
        
//        let imageData: Data? = screenImage.pngData()
//
//        if let imageData: Data? = try! NSKeyedArchiver.archivedData(withRootObject: screenImage, requiringSecureCoding: false) {
//            if !session.connectedPeers.isEmpty {
//                do {
//                    try session.send(imageData!, toPeers: session.connectedPeers, with: .reliable)
//                } catch {
//                    log.error("Error for sending: \(String(describing: error))")
//                }
//            }
//       }
        print("cached called")
        if let imageData = screenImage.jpegData(compressionQuality: 0.1) { // heavy
            print("success encode to jpeg Data")
            let encodeString:String = imageData.base64EncodedString(options: [])
            let data: Data? = encodeString.data(using: .utf8) // --> これを配信する
            do {
                try session.send(data!, toPeers: session.connectedPeers, with: .unreliable)
            } catch {
                log.error("Error for sending: \(String(describing: error))")
            }
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

        stream.delegate = self
        stream.schedule(in: .main, forMode: RunLoop.Mode.default)
        stream.open()

        var data:Data?
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            data?.append(buffer, count: read)
        }
        buffer.deallocate()

    }

    ///
    /// send メソッドから送られてきたDataをここで受け取る
    ///
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        currentScreenImage = nil
        print("recieve image")
        let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        if let imageData = Data(base64Encoded: responseString, options: []) {
            print("success Encoded")
            let image = UIImage(data: imageData, scale: 0.1) // --> これを表示する
            self.currentScreenImage = image
        }
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
