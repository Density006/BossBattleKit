import MultipeerConnectivity
import Combine
import SwiftUI

public class GameSession: NSObject, ObservableObject {
    
    // --- Published properties ---
    @Published public var currentGameState: GameState?
    @Published public var connectedPeers: [MCPeerID] = []
    @Published public var localPlayerID: UUID?
    @Published public var gameStarted: Bool = false
    @Published public var iAmBoss: Bool = false
    
    // NEW: This list will hold hosts we find
    @Published public var foundPeers: [MCPeerID] = []
    
    // --- Multipeer Properties ---
    private let serviceType = "boss-battle"
    private let myPeerID: MCPeerID
    public var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    
    // NEW: This replaces the pop-up. It's the "raw" browser.
    public var serviceBrowser: MCNearbyServiceBrowser!
    
    private var playerPeerMap: [MCPeerID: UUID] = [:]

    public init(playerName: String) {
        self.myPeerID = MCPeerID(displayName: playerName)
        super.init()
    }
    
    // --- Public API ---
    
    public func hostGame(boss: Boss) {
        self.iAmBoss = true
        self.localPlayerID = boss.id
        self.currentGameState = GameState(boss: boss)
        
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
        
        self.gameStarted = true
    }
    
    public func joinGame() {
        self.iAmBoss = false
        self.foundPeers = [] // Clear old results
        
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        
        // NEW: Instead of a pop-up, we start the "raw" browser
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    // NEW: This is called when you tap a host from the list
    public func invitePeer(_ peerID: MCPeerID) {
        // Invite the host to our session
        self.serviceBrowser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 30)
    }
    
    public func sendPlayerAttack(move: PlayerMove) {
        // This is simplified. We assume the first peer is the host.
        if let hostPeer = connectedPeers.first {
             sendData(.playerAttack(move), to: [hostPeer])
        }
    }
    
    public func sendBossAttack() {
        currentGameState?.bossAttack()
        broadcastGameState()
    }
    
    // --- Private Helper Methods ---
    private func sendData(_ data: GameData, to peers: [MCPeerID]) {
        guard !peers.isEmpty else { return }
        do {
            let encodedData = try JSONEncoder().encode(data)
            try session.send(encodedData, toPeers: peers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
    
    private func broadcastGameState() {
        guard iAmBoss, let state = currentGameState else { return }
        // Send to all *other* peers
        let playerPeers = connectedPeers.filter { $0 != myPeerID }
        sendData(.fullGameState(state), to: playerPeers)
    }
    
    private func handleReceivedData(_ data: GameData, from peerID: MCPeerID) {
        switch data {
        
        case .playerJoin(let player):
            guard iAmBoss else { return }
            self.playerPeerMap[peerID] = player.id
            self.currentGameState?.addPlayer(player)
            self.broadcastGameState()
            
        case .playerAttack(let move):
            guard iAmBoss else { return }
            if let playerID = self.playerPeerMap[peerID] {
                if playerID == self.currentGameState?.currentPlayerTurn {
                    self.currentGameState?.playerAttack(playerID: playerID, move: move)
                    self.broadcastGameState()
                }
            }

        case .fullGameState(let newGameState):
            guard !iAmBoss else { return }
            self.currentGameState = newGameState
        }
    }
}

// --- MPC Delegate Extensions ---
extension GameSession: MCSessionDelegate {
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                // Add to list, but avoid duplicates
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                
                if !self.iAmBoss {
                    // Stop searching once we're connected
                    self.serviceBrowser.stopBrowsingForPeers()
                    self.foundPeers = []
                    
                    // Send our player info
                    let player = Player(
                        id: UUID(),
                        name: self.myPeerID.displayName,
                        moves: [GameState.simpleStrike, GameState.heavyBash]
                    )
                    self.localPlayerID = player.id
                    self.sendData(.playerJoin(player), to: [peerID])
                    self.gameStarted = true
                }
                
            case .notConnected:
                self.connectedPeers.removeAll(where: { $0 == peerID })
                if self.iAmBoss {
                    if let playerID = self.playerPeerMap[peerID] {
                        self.currentGameState?.players.removeAll(where: { $0.id == playerID })
                        self.playerPeerMap.removeValue(forKey: peerID)
                        self.broadcastGameState()
                    }
                }
                
            default:
                break
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let gameData = try JSONDecoder().decode(GameData.self, from: data)
            DispatchQueue.main.async {
                self.handleReceivedData(gameData, from: peerID)
            }
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension GameSession: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Automatically accept all invitations
        invitationHandler(true, self.session)
    }
}

// NEW: This is the delegate for the "raw" browser
extension GameSession: MCNearbyServiceBrowserDelegate {
    
    // We found a host
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            // Add to our list so the UI can show it
            if !self.foundPeers.contains(peerID) {
                self.foundPeers.append(peerID)
            }
        }
    }
    
    // A host disappeared
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.foundPeers.removeAll(where: { $0 == peerID })
        }
    }
}
