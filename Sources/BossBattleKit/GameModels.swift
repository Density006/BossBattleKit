import Foundation

// --- All our data models must be "public" and "Codable" ---

public struct PlayerMove: Identifiable, Hashable, Codable {
    public var id = UUID()
    public var name: String
    public var damage: Int
    public var description: String
    
    public init(name: String, damage: Int, description: String) {
        self.name = name
        self.damage = damage
        self.description = description
    }
}

public struct BossCard: Identifiable, Hashable, Codable {
    public var id = UUID()
    public var name: String
    public var description: String
    
    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

public struct Player: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var health: Int
    public var customAvatarData: Data?
    public var moves: [PlayerMove]
    
    public init(id: UUID, name: String, moves: [PlayerMove]) {
        self.id = id
        self.name = name
        self.health = 20
        self.moves = moves
    }
}

public struct Boss: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var health: Int
    public var cards: [BossCard]
    
    public init(id: UUID, name: String, cards: [BossCard]) {
        self.id = id
        self.name = name
        self.health = 100
        self.cards = cards
    }
}

// --- MAIN GAME STATE STRUCT ---
public struct GameState: Codable {
    public var boss: Boss
    public var players: [Player]
    public var gameMessage: String
    public var currentPlayerTurn: UUID
    
    // Example data
    public static let simpleStrike = PlayerMove(name: "Simple Strike", damage: 5, description: "A quick hit.")
    public static let heavyBash = PlayerMove(name: "Heavy Bash", damage: 12, description: "A slow, powerful attack.")
    public static let healthDrain = BossCard(name: "Health Drain", description: "Steal 2 HP from every player.")
    
    public init(boss: Boss) {
        self.boss = boss
        self.players = []
        self.gameMessage = "Waiting for players to join..."
        self.currentPlayerTurn = boss.id
    }
    
    // --- GAME ACTIONS ---
    mutating public func addPlayer(_ player: Player) {
        players.append(player)
        if players.count == 1 {
            currentPlayerTurn = player.id
            gameMessage = "\(player.name) has joined! It's their turn."
        } else {
            gameMessage = "\(player.name) has joined."
        }
    }
    
    mutating public func playerAttack(playerID: UUID, move: PlayerMove) {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerID }) else { return }
        boss.health -= move.damage
        gameMessage = "\(players[playerIndex].name) used \(move.name) for \(move.damage) damage!"
        if boss.health <= 0 {
            gameMessage = "The Boss has been defeated! Players win!"
        } else {
            advanceTurn()
        }
    }
    
    mutating public func bossAttack() {
        if let randomPlayerIndex = players.indices.randomElement() {
            let damage = Int.random(in: 3...8)
            players[randomPlayerIndex].health -= damage
            let playerName = players[randomPlayerIndex].name
            gameMessage = "Boss attacks \(playerName) for \(damage) damage!"
            if players[randomPlayerIndex].health <= 0 {
                gameMessage += " \(playerName) has been knocked out!"
            }
        }
        advanceTurn()
    }
    
    mutating public func advanceTurn() {
        if players.isEmpty { currentPlayerTurn = boss.id; return }
        if currentPlayerTurn == boss.id {
            currentPlayerTurn = players[0].id
            return
        }
        if let currentIndex = players.firstIndex(where: { $0.id == currentPlayerTurn }) {
            let nextIndex = (currentIndex + 1)
            if nextIndex < players.count {
                currentPlayerTurn = players[nextIndex].id
            } else {
                currentPlayerTurn = boss.id
            }
        }
    }
}
