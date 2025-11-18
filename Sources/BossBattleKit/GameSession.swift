import MultipeerConnectivity
import Combine
import SwiftUI

public class GameSession: NSObject, ObservableObject {
    
    // --- Published properties will update our UI ---
    @Published public var currentGameState: GameState?
    @Published public var connectedPeers: [MCPeerID] = []
    @Published public var localPlayerID: UUID?
    @Published public var gameStarted: Bool = false
    @Published public var iAmBoss: Bool = false
    
    /// This new property will trigger the browser sheet
    @Published public var isShowingBrowser: Bool = false
    
    // --- Multipeer Properties ---
    private let serviceType = "boss-battle"
    private let myPeerID: MCPeerID
    public var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    public var browser: MCBrowserViewController?
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
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        
        // Create the browser and show it
        self.browser = MCBrowserViewController(serviceType: serviceType, session: self.session)
        self.browser?.delegate = self
        
        DispatchQueue.main.async {
            self.isShowingBrowser = true
        }
    }
    
    public func sendPlayerAttack(move: PlayerMove) {
        if let hostPeer = connectedPeers.first(where: { playerPeerMap.keys.contains($0) }) {
             sendData(.playerAttack(move), to: [hostPeer])
        } else if let hostPeer = connectedPeers.first {
            // Fallback for the very first connection
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
        sendData(.fullGameState(state), to: connectedPeers)
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
                self.connectedPeers.append(peerID)
                if !self.iAmBoss {
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
                    // Handle player disconnect
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
        invitationHandler(true, self.session)
    }
}

extension GameSession: MCBrowserViewControllerDelegate {
    public func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        DispatchQueue.main.async {
            self.isShowingBrowser = false
        }
        browserViewController.dismiss(animated: true)
    }
    
    public func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        DispatchQueue.main.async {
            self.isShowingBrowser = false
        }
        browserViewController.dismiss(animated: true)
    }
}
