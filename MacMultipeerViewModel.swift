import Foundation
import Combine
import MultipeerConnectivity

class MacMultipeerConnectivityViewModel: ObservableObject {
    @Published var receivedMessages: [String] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var roomCode: String = ""
    @Published var isHosting = false
    @Published var isBrowsing = false
    @Published var elementAssignments: [String: String] = [:]
    @Published var readyPlayers: Set<String> = []
    
    // New properties for element-specific messages
    @Published var fireReceivedMessages: [String] = []
    @Published var windReceivedMessages: [String] = []
    @Published var waterReceivedMessages: [String] = []
    @Published var rockReceivedMessages: [String] = []
    
    private let manager: MacMultipeerConnectivityManager
    private var cancellables: Set<AnyCancellable> = []
    private var clearMessageTimer: Timer?
    
    init() {
        manager = MacMultipeerConnectivityManager()
        setupBindings()
        startClearMessageTimer()
    }
    
    private func setupBindings() {
        manager.$receivedMessages
            .receive(on: DispatchQueue.main)
            .assign(to: \.receivedMessages, on: self)
            .store(in: &cancellables)
        
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
        
        manager.$fireReceivedMessages
            .receive(on: DispatchQueue.main)
            .assign(to: \.fireReceivedMessages, on: self)
            .store(in: &cancellables)
        
        manager.$windReceivedMessages
            .receive(on: DispatchQueue.main)
            .assign(to: \.windReceivedMessages, on: self)
            .store(in: &cancellables)
        
        manager.$waterReceivedMessages
            .receive(on: DispatchQueue.main)
            .assign(to: \.waterReceivedMessages, on: self)
            .store(in: &cancellables)
        
        manager.$rockReceivedMessages
            .receive(on: DispatchQueue.main)
            .assign(to: \.rockReceivedMessages, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        clearMessageTimer?.invalidate()
    }
    
    private func startClearMessageTimer() {
        clearMessageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.clearElementMessages()
        }
    }
    
    private func clearElementMessages() {
        DispatchQueue.main.async { [weak self] in
            self?.fireReceivedMessages.removeAll()
            self?.windReceivedMessages.removeAll()
            self?.waterReceivedMessages.removeAll()
            self?.rockReceivedMessages.removeAll()
        }
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
}
