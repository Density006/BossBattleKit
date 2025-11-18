import Foundation
import Combine // Used for ObservableObject

// --- CARD & MOVE DEFINITIONS ---

/// A move a player can use
public struct PlayerMove: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var damage: Int
    public var description: String
}

/// A card the boss can play
public struct BossCard: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var description: String
    // You can add a closure here to define the card's effect
    // public var effect: (GameState) -> Void
}

// --- CHARACTER DEFINITIONS ---

/// Represents a single player
public struct Player: Identifiable {
    public let id = UUID()
    public var name: String
    public var health: Int = 20
    
    /// This is the "hook" for your imported drawings!
    /// The app will load image data from Sketchbook and store it here.
    public var customAvatarData: Data?
    
    public var moves: [PlayerMove]
}

/// Represents the Boss
public struct Boss: Identifiable {
    public let id = UUID()
    public var name: String = "The Unspeakable"
    public var health: Int = 100
    public var cards: [BossCard]
}

// --- MAIN GAME STATE ---

/// This class manages the entire game and notifies the UI of any changes.
/// This is the "local multiplayer" part—everyone shares this one object.
public class GameState: ObservableObject {
    
    @Published public var boss: Boss
    @Published public var players: [Player]
    @Published public var gameMessage: String
    @Published public var currentPlayerTurn: UUID // ID of the player whose turn it is
    
    // Example player moves
    public static let simpleStrike = PlayerMove(name: "Simple Strike", damage: 5, description: "A quick hit.")
    public static let heavyBash = PlayerMove(name: "Heavy Bash", damage: 12, description: "A slow, powerful attack.")
    
    // Example boss cards
    public static let healthDrain = BossCard(name: "Health Drain", description: "Steal 2 HP from every player.")
    
    /// Creates a new game with 1 to 4 players.
    public init(playerNames: [String]) {
        // Create players
        var tempPlayers: [Player] = []
        for name in playerNames.prefix(4) { // Enforce 4-player max
            let player = Player(
                name: name,
                moves: [GameState.simpleStrike, GameState.heavyBash] // Give everyone default moves
            )
            tempPlayers.append(player)
        }
        self.players = tempPlayers
        
        // Create boss
        self.boss = Boss(
            cards: [GameState.healthDrain]
        )
        
        self.gameMessage = "A new battle has begun!"
        self.currentPlayerTurn = tempPlayers.first?.id ?? UUID()
    }
    
    // --- GAME ACTIONS ---
    
    /// A player uses a move against the boss
    public func playerAttack(playerID: UUID, move: PlayerMove) {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerID }) else { return }
        guard playerID == currentPlayerTurn else {
            gameMessage = "It's not \(players[playerIndex].name)'s turn!"
            return
        }
        
        boss.health -= move.damage
        gameMessage = "\(players[playerIndex].name) used \(move.name) for \(move.damage) damage!"
        
        if boss.health <= 0 {
            gameMessage = "The Boss has been defeated! Players win!"
        } else {
            // Advance to the next player's turn or the boss's turn
            advanceTurn()
        }
    }
    
    /// The boss takes its turn
    public func bossAttack() {
        guard currentPlayerTurn == boss.id else {
            gameMessage = "It's not the Boss's turn!"
            return
        }

        // Simple boss logic: attack a random player
        if let randomPlayerIndex = players.indices.randomElement() {
            let damage = Int.random(in: 3...8)
            players[randomPlayerIndex].health -= damage
            let playerName = players[randomPlayerIndex].name
            gameMessage = "Boss attacks \(playerName) for \(damage) damage!"
            
            if players[randomPlayerIndex].health <= 0 {
                gameMessage += " \(playerName) has been knocked out!"
            }
        }
        
        // Advance to the first player's turn
        advanceTurn()
    }
    
    /// Moves the turn to the next player, or to the boss.
    public func advanceTurn() {
        if currentPlayerTurn == boss.id {
            // If it was the boss's turn, go to the first player
            currentPlayerTurn = players.first?.id ?? UUID()
            return
        }
        
        if let currentIndex = players.firstIndex(where: { $0.id == currentPlayerTurn }) {
            let nextIndex = (currentIndex + 1)
            if nextIndex < players.count {
                // Next player's turn
                currentPlayerTurn = players[nextIndex].id
            } else {
                // All players have gone, it's the boss's turn
                currentPlayerTurn = boss.id
            }
        }
    }
}
