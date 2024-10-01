//
//  MacMultipeerBundle.swift
//  MacMultipeerBundle
//
//  Created by Rizky Azmi Swandy on 27/09/24.
//

import Foundation
import MultipeerConnectivity

class MacMultipeerConnectivityManager: NSObject, ObservableObject {
    private let serviceType = "msg-transfer"
    
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var roomCode: String = ""
    @Published var elementAssignments: [String: MCPeerID] = [:]
    @Published var readyPlayers: Set<MCPeerID> = []
    @Published var elementMessageQueues: [String: [String]] = [
        "Fire": [], "Water": [], "Rock": [], "Wind": []
    ]
    
    let elements = ["Fire", "Water", "Rock", "Wind"]
    
    override init() {
        super.init()
        
        peerID = MCPeerID(displayName: "Mac Host")
        
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    func hostRoom() {
        roomCode = generateRoomCode()
        print("Debug: Hosting room with code: \(roomCode)")
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["roomCode": roomCode], serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        print("Debug: Started advertising peer")
        updateConnectedPeers()
    }
    
    func stopHosting() {
        print("Debug: Stopping hosting")
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        roomCode = ""
        elementAssignments.removeAll()
        readyPlayers.removeAll()
        elementMessageQueues = ["Fire": [], "Water": [], "Rock": [], "Wind": []]
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
    }
    
    func sendMessage(_ message: String, to peers: [MCPeerID]) {
        guard !peers.isEmpty else { return }
        
        if let messageData = message.data(using: .utf8) {
            do {
                try session.send(messageData, toPeers: peers, with: .reliable)
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateConnectedPeers() {
        DispatchQueue.main.async {
            self.connectedPeers = self.session.connectedPeers
            self.assignElementsToPeers()
        }
    }

    private func generateRoomCode() -> String {
        let letters = "123456789"
        return String((0..<4).map{ _ in letters.randomElement()! })
    }
    
    private func assignElementsToPeers() {
        let unassignedPeers = connectedPeers.filter { peer in
            !elementAssignments.values.contains(peer)
        }
        
        let availableElements = elements.filter { element in
            !elementAssignments.keys.contains(element)
        }
        
        let shuffledElements = availableElements.shuffled()
        
        for (index, peer) in unassignedPeers.enumerated() where index < shuffledElements.count {
            let element = shuffledElements[index]
            elementAssignments[element] = peer
            sendMessage("Assigned:\(element)", to: [peer])
            print("Debug: Assigned \(element) to \(peer.displayName)")
        }
    }
    
    private func handleReadyMessage(from peer: MCPeerID) {
        readyPlayers.insert(peer)
        if readyPlayers.count == connectedPeers.count {
            sendMessage("StartGame", to: connectedPeers)
        }
    }
    
    private func processReceivedMessage(_ message: String, fromPeer peerID: MCPeerID) {
        let trimmedMessage = message.replacingOccurrences(of: "Unassigned: ", with: "")
        print("Debug: Received message: \(trimmedMessage)")
        
        let parts = trimmedMessage.split(separator: ":")
        if parts.count == 3 {
            let element = String(parts[0])
            let action = String(parts[1])
            let confirmElement = String(parts[2])
            
            if element == confirmElement {
                DispatchQueue.main.async {
                    self.elementMessageQueues[element, default: []].append(trimmedMessage)
                }
                print("Debug: Added message for \(element): \(trimmedMessage)")
            } else {
                print("Debug: Element mismatch in message: \(trimmedMessage)")
            }
        } else if trimmedMessage == "Ready" {
            self.handleReadyMessage(from: peerID)
        } else {
            print("Debug: Received unrecognized message format: \(trimmedMessage)")
        }
    }
}

extension MacMultipeerConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.assignElementsToPeers()
                }
            case .notConnected:
                if let index = self.connectedPeers.firstIndex(of: peerID) {
                    self.connectedPeers.remove(at: index)
                }
                self.readyPlayers.remove(peerID)
                if let (element, _) = self.elementAssignments.first(where: { $0.value == peerID }) {
                    self.elementAssignments.removeValue(forKey: element)
                }
            default:
                break
            }
            self.updateConnectedPeers()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.processReceivedMessage(message, fromPeer: peerID)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MacMultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error.localizedDescription)")
    }
}

extension MacMultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let peerRoomCode = info?["roomCode"], peerRoomCode == roomCode else {
            return
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error.localizedDescription)")
    }
}
