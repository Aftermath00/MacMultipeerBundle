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
    
    @Published var receivedMessages: [String] = []
    @Published var fireReceivedMessages: [String] = []
    @Published var waterReceivedMessages: [String] = []
    @Published var windReceivedMessages: [String] = []
    @Published var rockReceivedMessages: [String] = []

    @Published var connectedPeers: [MCPeerID] = []
    @Published var roomCode: String = ""
    @Published var elementAssignments: [String: MCPeerID] = [:]
    @Published var readyPlayers: Set<MCPeerID> = []
        
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
    }
    
    func updateConnectedPeers() {
        DispatchQueue.main.async {
            self.connectedPeers = self.session.connectedPeers
            self.assignElementsToPeers()
        }
    }

    private func generateRoomCode() -> String {
        let letters = "123456789"
        return String((0..<4).map{ _ in letters.randomElement()! })
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
        } else {
            print("Error encoding message to data")
        }
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
            // All players are ready, start the game
            sendMessage("StartGame", to: connectedPeers)
        }
    }
}

extension MacMultipeerConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            print("Debug: Peer \(peerID.displayName) changed state to: \(state.rawValue)")
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    print("Debug: Peer connected: \(peerID.displayName)")
                    self.assignElementsToPeers() // Only assign elements for new connections
                }
            case .notConnected:
                if let index = self.connectedPeers.firstIndex(of: peerID) {
                    self.connectedPeers.remove(at: index)
                }
                print("Debug: Peer disconnected: \(peerID.displayName)")
                self.readyPlayers.remove(peerID)
                // Remove the assignment for the disconnected peer
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
    
    private func processReceivedMessage(_ message: String, fromPeer peerID: MCPeerID) {
        let trimmedMessage = message.replacingOccurrences(of: "Unassigned: ", with: "")
        print("Debug: Received message: \(trimmedMessage)")
        receivedMessages.append(trimmedMessage)
        
        let parts = trimmedMessage.split(separator: ":")
        if parts.count == 3 {
            let element = String(parts[0])
            let action = String(parts[1])
            let confirmElement = String(parts[2])
            
            if element == confirmElement {
                switch element {
                case "Fire":
                    fireReceivedMessages.append(trimmedMessage)
                case "Wind":
                    windReceivedMessages.append(trimmedMessage)
                case "Water":
                    waterReceivedMessages.append(trimmedMessage)
                case "Rock":
                    rockReceivedMessages.append(trimmedMessage)
                default:
                    print("Debug: Unknown element: \(element)")
                }
            } else {
                print("Debug: Element mismatch in message: \(trimmedMessage)")
            }
        } else if trimmedMessage == "Ready" {
            self.handleReadyMessage(from: peerID)
        } else {
            print("Debug: Received unrecognized message format: \(trimmedMessage)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MacMultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Debug: Received invitation from peer: \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Debug: Failed to start advertising: \(error.localizedDescription)")
    }
}

extension MacMultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Debug: Found peer: \(peerID.displayName), info: \(String(describing: info))")
        guard let peerRoomCode = info?["roomCode"], peerRoomCode == roomCode else {
            print("Debug: Peer room code doesn't match. Ignoring.")
            return
        }
        print("Debug: Inviting peer to join session")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Debug: Lost peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Debug: Failed to start browsing: \(error.localizedDescription)")
    }
}
