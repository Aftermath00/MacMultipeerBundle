//
//  MacMultipeerBridge.swift
//  MacMultipeerBundle
//
//  Created by Rizky Azmi Swandy on 27/09/24.
//

import Foundation

@objc(MacMultipeerConnectivityBridge)
public class MacMultipeerConnectivityBridge: NSObject {
    @objc public static let shared = MacMultipeerConnectivityBridge()
    
    private let viewModel = MacMultipeerConnectivityViewModel()
    
    private override init() {
        super.init()
    }
    
    @objc public func hostRoomNative() {
        viewModel.hostRoom()
    }
    
    @objc public func stopHostingNative() {
        viewModel.stopHosting()
    }
    
    @objc public func startBrowsingNative() {
        viewModel.startBrowsing()
    }
    
    @objc public func stopBrowsingNative() {
        viewModel.stopBrowsing()
    }
    
    @objc public func sendMessageNative(_ message: String) {
        viewModel.sendMessage(message)
    }
    
    @objc public func getReceivedMessagesNative() -> [String] {
        return viewModel.receivedMessages
    }
    
    @objc public func getConnectedPeersCountNative() -> Int {
        return viewModel.connectedPeers.count
    }
    
    @objc public func getConnectedPeersNative() -> [String] {
        return viewModel.connectedPeers.map { $0.displayName }
    }
    
    @objc public func getRoomCodeNative() -> String {
        return viewModel.roomCode
    }
    
    @objc public func isHostingNative() -> Bool {
        return viewModel.isHosting
    }
    
    @objc public func isBrowsingNative() -> Bool {
        return viewModel.isBrowsing
    }
    
    @objc public func getElementAssignmentsNative() -> [String: String] {
        return viewModel.elementAssignments
    }
    
    @objc public func getReadyPlayersNative() -> [String] {
        return Array(viewModel.readyPlayers)
    }
    
    @objc public func startGameNative() {
        viewModel.startGame()
    }
    
    @objc public func getFireReceivedMessagesNative() -> [String] {
        return viewModel.fireReceivedMessages
    }
    
    @objc public func getWindReceivedMessagesNative() -> [String] {
        return viewModel.windReceivedMessages
    }
    
    @objc public func getWaterReceivedMessagesNative() -> [String] {
        return viewModel.waterReceivedMessages
    }
    
    @objc public func getRockReceivedMessagesNative() -> [String] {
        return viewModel.rockReceivedMessages
    }
}

@_cdecl("InitializePlugin")
public func InitializePlugin() {
    _ = MacMultipeerConnectivityBridge.shared
    print("MacMultipeerConnectivityBridge initialized")
}

@_cdecl("HostRoomNative")
public func HostRoomNative() {
    MacMultipeerConnectivityBridge.shared.hostRoomNative()
}

@_cdecl("StopHostingNative")
public func StopHostingNative() {
    MacMultipeerConnectivityBridge.shared.stopHostingNative()
}

@_cdecl("StartBrowsingNative")
public func StartBrowsingNative() {
    MacMultipeerConnectivityBridge.shared.startBrowsingNative()
}

@_cdecl("StopBrowsingNative")
public func StopBrowsingNative() {
    MacMultipeerConnectivityBridge.shared.stopBrowsingNative()
}

@_cdecl("SendMessageNative")
public func SendMessageNative(_ message: UnsafePointer<CChar>) {
    let swiftMessage = String(cString: message)
    MacMultipeerConnectivityBridge.shared.sendMessageNative(swiftMessage)
}

@_cdecl("GetReceivedMessagesNative")
public func GetReceivedMessagesNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let messages = MacMultipeerConnectivityBridge.shared.getReceivedMessagesNative()
    let count = messages.count
    let arrayPtr = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: count + 1)
    
    for (index, message) in messages.enumerated() {
        arrayPtr[index] = strdup(message)
    }
    arrayPtr[count] = nil  // Null-terminate the array
    
    return arrayPtr
}

@_cdecl("GetConnectedPeersCountNative")
public func GetConnectedPeersCountNative() -> Int32 {
    return Int32(MacMultipeerConnectivityBridge.shared.getConnectedPeersCountNative())
}

@_cdecl("GetConnectedPeersNative")
public func GetConnectedPeersNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let peers = MacMultipeerConnectivityBridge.shared.getConnectedPeersNative()
    let count = peers.count
    let arrayPtr = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: count + 1)
    
    for (index, peer) in peers.enumerated() {
        arrayPtr[index] = strdup(peer)
    }
    arrayPtr[count] = nil  // Null-terminate the array
    
    return arrayPtr
}


@_cdecl("GetRoomCodeNative")
public func GetRoomCodeNative() -> UnsafeMutablePointer<CChar>? {
    let code = MacMultipeerConnectivityBridge.shared.getRoomCodeNative()
    return strdup(code)
}

@_cdecl("IsHostingNative")
public func IsHostingNative() -> Bool {
    return MacMultipeerConnectivityBridge.shared.isHostingNative()
}

@_cdecl("IsBrowsingNative")
public func IsBrowsingNative() -> Bool {
    return MacMultipeerConnectivityBridge.shared.isBrowsingNative()
}

@_cdecl("GetElementAssignmentsNative")
public func GetElementAssignmentsNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let assignments = MacMultipeerConnectivityBridge.shared.getElementAssignmentsNative()
    let count = assignments.count * 2 // Key-value pairs
    let arrayPtr = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: count + 1)
    
    var index = 0
    for (element, player) in assignments {
        arrayPtr[index] = strdup(element)
        index += 1
        arrayPtr[index] = strdup(player)
        index += 1
    }
    arrayPtr[count] = nil  // Null-terminate the array
    
    return arrayPtr
}

@_cdecl("GetReadyPlayersNative")
public func GetReadyPlayersNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let players = MacMultipeerConnectivityBridge.shared.getReadyPlayersNative()
    let count = players.count
    let arrayPtr = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: count + 1)
    
    for (index, player) in players.enumerated() {
        arrayPtr[index] = strdup(player)
    }
    arrayPtr[count] = nil  // Null-terminate the array
    
    return arrayPtr
}

@_cdecl("GetFireReceivedMessagesNative")
public func GetFireReceivedMessagesNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let messages = MacMultipeerConnectivityBridge.shared.getFireReceivedMessagesNative()
    return createStringArray(from: messages)
}

@_cdecl("GetWindReceivedMessagesNative")
public func GetWindReceivedMessagesNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let messages = MacMultipeerConnectivityBridge.shared.getWindReceivedMessagesNative()
    return createStringArray(from: messages)
}

@_cdecl("GetWaterReceivedMessagesNative")
public func GetWaterReceivedMessagesNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let messages = MacMultipeerConnectivityBridge.shared.getWaterReceivedMessagesNative()
    return createStringArray(from: messages)
}

@_cdecl("GetRockReceivedMessagesNative")
public func GetRockReceivedMessagesNative() -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let messages = MacMultipeerConnectivityBridge.shared.getRockReceivedMessagesNative()
    return createStringArray(from: messages)
}

private func createStringArray(from messages: [String]) -> UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let count = messages.count
    let arrayPtr = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: count + 1)
    
    for (index, message) in messages.enumerated() {
        arrayPtr[index] = strdup(message)
    }
    arrayPtr[count] = nil  // Null-terminate the array
    
    return arrayPtr
}

@_cdecl("StartGameNative")
public func StartGameNative() {
    MacMultipeerConnectivityBridge.shared.startGameNative()
}

@_cdecl("FreeStringNative")
public func FreeStringNative(_ ptr: UnsafeMutablePointer<CChar>?) {
    if let ptr = ptr {
        free(ptr)
    }
}

@_cdecl("FreeStringArrayNative")
public func FreeStringArrayNative(_ array: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) {
    var ptr = array
    while let cString = ptr.pointee {
        free(UnsafeMutableRawPointer(mutating: cString))
        ptr += 1
    }
    array.deallocate()
}
