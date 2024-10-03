//
//  MacMultipeerBundle.swift
//  MacMultipeerBundle
//
//  Created by Rizky Azmi Swandy on 27/09/24.
//

import Foundation
import MultipeerConnectivity
import Network

class MacMultipeerConnectivityManager: NSObject, ObservableObject {
    private let serviceType = "msg-transfer"
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    private var networkMonitor: NWPathMonitor?
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedMessages: [String] = []
    @Published var elementAssignments: [MCPeerID: String] = [:]
    @Published var roomCode: String = ""
    
    private let elements = ["Fire", "Water", "Rock", "Wind"]
    private var availableElements: [String]
    private var pendingAssignments: [String: MCPeerID] = [:]
    @Published var elementMessages: [String: [String]] = [
        "Fire": [],
        "Water": [],
        "Rock": [],
        "Wind": []
    ]
    
    private var clearMessagesTimer: Timer?
    
    override init() {
        self.availableElements = elements
        super.init()
        setupSession()
        setupNetworkMonitoring()
    }
    
    private func setupSession() {
        let peerID = MCPeerID(displayName: "Mac Host")
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    private func startClearMessagesTimer() {
        clearMessagesTimer?.invalidate() // Invalidate any existing timer
        clearMessagesTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.clearAllElementMessages()
        }
    }
    
    private func clearAllElementMessages() {
        DispatchQueue.main.async {
            for element in self.elements {
                self.elementMessages[element] = []
            }
            print("Debug: Cleared all element messages")
            self.objectWillChange.send()
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                DispatchQueue.main.async {
                    self?.handleNetworkChange()
                }
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global(qos: .background))
    }
    
    private func handleNetworkChange() {
        print("Debug: Network change detected. Reinitializing session.")
        stopHosting()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.setupSession()
            self?.hostRoom()
        }
    }
    
    private func generateRoomCode() -> String {
        let letters = "123456789"
        return String((0..<4).map{ _ in letters.randomElement()! })
    }
    
    func hostRoom() {
        roomCode = generateRoomCode()
        stopHosting() // Ensure we're not already hosting and clear all data
        setupSession() // Create a new session
        advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: ["roomCode": roomCode], serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        startClearMessagesTimer() // Start the timer to clear messages

        print("Debug: Started hosting room with code: \(roomCode)")
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session.disconnect()
        session = nil  // Completely remove the session
        connectedPeers.removeAll()
        elementAssignments.removeAll()
        pendingAssignments.removeAll()
        
        clearMessagesTimer?.invalidate() // Stop the timer
        clearMessagesTimer = nil
        
        availableElements = elements
        elementMessages = [
            "Fire": [],
            "Water": [],
            "Rock": [],
            "Wind": []
        ]
        print("Debug: Stopped hosting room and cleared all data")
    }
    
    func updateConnectedPeers() {
        DispatchQueue.main.async {
            self.connectedPeers = self.session.connectedPeers
        }
    }
    
    func getRoomCode() -> String {
        return roomCode
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
    }
    
    func sendMessage(_ message: String, to peers: [MCPeerID]? = nil) {
        let targetPeers = peers ?? connectedPeers
        guard !targetPeers.isEmpty else {
            print("Debug: No connected peers to send message to")
            return
        }
        
        do {
            let data = message.data(using: .utf8)!
            try session.send(data, toPeers: targetPeers, with: .reliable)
            print("Debug: Sent message to peers: \(message)")
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }

    private func assignElementToPeer(_ peer: MCPeerID) {
        if elements.contains(peer.displayName) {
            if let existingAssignment = elementAssignments.first(where: { $0.value == peer.displayName }) {
                elementAssignments.removeValue(forKey: existingAssignment.key)
            }
            elementAssignments[peer] = peer.displayName
            pendingAssignments.removeValue(forKey: peer.displayName)
            print("Debug: Reassigned \(peer.displayName) to peer \(peer)")
        } else if pendingAssignments[peer.displayName] == nil {
            guard !availableElements.isEmpty else {
                print("Debug: No available elements to assign")
                return
            }
            let randomElement = availableElements.removeFirst()
            elementAssignments[peer] = randomElement
            pendingAssignments[randomElement] = peer
            
            sendMessage("Assigned:\(randomElement)")
            print("Debug: Assigned \(randomElement) to peer \(peer)")
        }
    }
    
    private func handleReceivedMessage(_ message: String, from peerID: MCPeerID) {
        print("Debug: Received message from \(peerID.displayName): \(message)")
        DispatchQueue.main.async {
            if let element = self.elementAssignments[peerID] {
                self.elementMessages[element, default: []].append("\(peerID.displayName):\(message)")
                // Broadcast the message to all peers
                self.sendMessage("ElementMessage:\(element):\(message)")
            }
            self.receivedMessages.append("\(peerID.displayName): \(message)")
            self.objectWillChange.send()
        }
    }
    
    func clearElementMessages(_ element: String) {
        elementMessages[element]?.removeAll()
    }
}

// Implement MCSessionDelegate, MCNearbyServiceAdvertiserDelegate here
// Make sure to add proper error handling and logging in these delegate methods
extension MacMultipeerConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            print("Debug: Peer \(peerID.displayName) changed state to: \(state.rawValue)")
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.assignElementToPeer(peerID)
                }
            case .notConnected:
                if let index = self.connectedPeers.firstIndex(of: peerID) {
                    self.connectedPeers.remove(at: index)
                }
                if let element = self.elementAssignments.removeValue(forKey: peerID) {
                    self.availableElements.append(element)
                    self.pendingAssignments.removeValue(forKey: element)
                }
                print("Debug: Peer disconnected: \(peerID.displayName)")
            case .connecting:
                print("Debug: Peer connecting: \(peerID.displayName)")
            @unknown default:
                print("Debug: Unknown state for peer \(peerID.displayName): \(state.rawValue)")
            }
            self.objectWillChange.send()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            print("Debug: Received raw data: \(data.base64EncodedString())")
            print("Debug: Decoded message: \(message)")
            handleReceivedMessage(message, from: peerID)
        } else {
            print("Debug: Received invalid data from \(peerID.displayName)")
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

extension Substring {
    var string: String {
        return String(self)
    }
}
