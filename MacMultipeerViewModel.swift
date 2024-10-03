import Foundation
import Combine
import MultipeerConnectivity

class MacMultipeerViewModel: ObservableObject {
    private let manager: MacMultipeerConnectivityManager
    private var cancellables: Set<AnyCancellable> = []

    @Published var connectedPeers: [String] = []
    @Published var receivedMessages: [String] = []
    @Published var elementAssignments: [String: String] = [:]
    @Published var elementMessages: [String: [String]] = [
        "Fire": [],
        "Water": [],
        "Rock": [],
        "Wind": []
    ]
    @Published var roomCode: String = ""
    @Published var isHosting: Bool = false
    @Published var isBrowsing = false

    init() {
        manager = MacMultipeerConnectivityManager()
        setupBindings()
    }

    private func setupBindings() {
        manager.$connectedPeers
            .receive(on: DispatchQueue.main)
            .map { peers in peers.map { $0.displayName } }
            .assign(to: &$connectedPeers)

        manager.$roomCode
            .receive(on: DispatchQueue.main)
            .assign(to: \.roomCode, on: self)
            .store(in: &cancellables)
        
        manager.$receivedMessages
            .assign(to: &$receivedMessages)
        
        manager.$elementAssignments
            .map { assignments in
                Dictionary(uniqueKeysWithValues: assignments.map { (key, value) in
                    (key.displayName, value)
                })
            }
            .assign(to: &$elementAssignments)
        
        manager.$elementMessages
            .assign(to: &$elementMessages)
    }

    func hostRoom() {
        manager.hostRoom()
        isHosting = true
    }
    
    func stopHosting() {
        manager.stopHosting()
        isHosting = false
    }
    
    func startBrowsing() {
        manager.startBrowsing()
        isBrowsing = true
    }
    
    func stopBrowsing() {
        manager.stopBrowsing()
        isBrowsing = false
    }
    
    func sendMessage(_ message: String) {
        manager.sendMessage(message)
    }
    
    func startGame() {
        manager.sendMessage("StartGame", to: manager.connectedPeers)
    }
    
    func clearElementMessages(_ element: String) {
        manager.clearElementMessages(element)
    }
}
