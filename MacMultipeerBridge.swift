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
    
    private let viewModel = MacMultipeerViewModel()
    
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
    
    @objc public func getRoomCodeNative() -> String {
        return viewModel.roomCode
    }
    
    @objc public func getIsHosting() -> Bool {
        return viewModel.isHosting
    }
    
    @objc public func getConnectedPeersCountNative() -> Int {
        return viewModel.connectedPeers.count
    }
    
    @objc public func getConnectedPeersNative() -> [String] {
        return viewModel.connectedPeers
    }
    
    @objc public func getElementAssignmentsNative() -> [String: String] {
        return viewModel.elementAssignments
    }
    
    @objc public func getElementMessagesNative() -> [String: [String]] {
        return viewModel.elementMessages
    }
    
    @objc public func clearElementMessagesNative(_ element: String)  {
        return viewModel.clearElementMessages(element)
    }
}

@_cdecl("InitializeMultipeerConnectivityBridgeNative")
public func InitializeMultipeerConnectivityBridgeNative() {
    _ = MacMultipeerConnectivityBridge.shared
}

@_cdecl("ClearElementMessagesNative")
public func clearElementMessagesNative(_ element: UnsafePointer<CChar>) {
    let element = String(cString: element)
    MacMultipeerConnectivityBridge.shared.clearElementMessagesNative(element)
}

@_cdecl("hostRoomNative")
public func hostRoomNative() {
    MacMultipeerConnectivityBridge.shared.hostRoomNative()
}

@_cdecl("StopHostingNative")
public func StopHostingNative() {
    MacMultipeerConnectivityBridge.shared.stopHostingNative()
}

@_cdecl("sendMessageNative")
public func sendMessageNative(_ message: UnsafePointer<CChar>) {
    let swiftMessage = String(cString: message)
    MacMultipeerConnectivityBridge.shared.sendMessageNative(swiftMessage)
}

@_cdecl("getRoomCodeNative")
public func getRoomCodeNative() -> UnsafeMutablePointer<CChar> {
    let roomCode = MacMultipeerConnectivityBridge.shared.getRoomCodeNative()
    return strdup(roomCode)
}

@_cdecl("getIsHostingNative")
public func getIsHosting() -> Bool {
    return MacMultipeerConnectivityBridge.shared.getIsHosting()
}

@_cdecl("GetConnectedPeersCountNative")
public func GetConnectedPeersCountNative() -> Int {
    return MacMultipeerConnectivityBridge.shared.getConnectedPeersCountNative()
}

@_cdecl("getConnectedPeersNative")
public func getConnectedPeersNative() -> UnsafeMutablePointer<CChar> {
    let peers = MacMultipeerConnectivityBridge.shared.getConnectedPeersNative().joined(separator: ",")
    return strdup(peers)
}

@_cdecl("getElementAssignmentsNative")
public func getElementAssignments() -> UnsafeMutablePointer<CChar> {
    let assignments = MacMultipeerConnectivityBridge.shared.getElementAssignmentsNative().map { "\($0):\($1)" }.joined(separator: ",")
    return strdup(assignments)
}

@_cdecl("getElementMessagesNative")
public func getElementMessages() -> UnsafeMutablePointer<CChar> {
    let messages = MacMultipeerConnectivityBridge.shared.getElementMessagesNative().map { element, msgs in
        "\(element):\(msgs.joined(separator: "|"))"
    }.joined(separator: ",")
    return strdup(messages)
}

@_cdecl("FreeStringNative")
public func FreeStringNative(_ ptr: UnsafeMutablePointer<CChar>?) {
    if let ptr = ptr {
        ptr.deallocate()
    }
}
