import Foundation
import MultipeerConnectivity
import Combine

class MacMultipeerConnectivityViewModel: ObservableObject {
    @Published var connectedPeers: [MCPeerID] = []
    @Published var roomCode: String = ""
    @Published var isHosting = false
    @Published var isBrowsing = false
    @Published var elementAssignments: [String: String] = [:]
    @Published var readyPlayers: Set<String> = []
    @Published var elementMessageQueues: [String: [String]] = [:]
    
    private let manager: MacMultipeerConnectivityManager
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        manager = MacMultipeerConnectivityManager()
        setupBindings()
    }
    
    private func setupBindings() {
        manager.$connectedPeers
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectedPeers, on: self)
            .store(in: &cancellables)
        
        manager.$roomCode
            .receive(on: DispatchQueue.main)
            .assign(to: \.roomCode, on: self)
            .store(in: &cancellables)
        
        manager.$elementAssignments
            .receive(on: DispatchQueue.main)
            .map { dict in
                dict.mapValues { $0.displayName }
            }
            .assign(to: \.elementAssignments, on: self)
            .store(in: &cancellables)
        
        manager.$readyPlayers
            .receive(on: DispatchQueue.main)
            .map { Set($0.map { $0.displayName }) }
            .assign(to: \.readyPlayers, on: self)
            .store(in: &cancellables)
        
        manager.$elementMessageQueues
            .receive(on: DispatchQueue.main)
            .assign(to: \.elementMessageQueues, on: self)
            .store(in: &cancellables)
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
        manager.sendMessage(message, to: manager.connectedPeers)
    }
    
    func startGame() {
        manager.sendMessage("StartGame", to: manager.connectedPeers)
    }
    
    func getNextElementMessage(_ element: String) -> String? {
        if var messages = elementMessageQueues[element], !messages.isEmpty {
            let message = messages.removeFirst()
            elementMessageQueues[element] = messages
            return message
        }
        return nil
    }
    
    func clearElementMessages(_ element: String) {
        elementMessageQueues[element]?.removeAll()
    }
}
