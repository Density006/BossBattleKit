import SwiftUI

/// A simple view that displays the current game state.
public struct BossBattleView: View {
    
    /// This view "observes" the game state. When the state changes,
    /// the view automatically updates.
    @ObservedObject public var gameState: GameState
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            
            // --- BOSS ---
            VStack {
                Text(gameState.boss.name)
                    .font(.largeTitle.bold())
                // This is where you would show the boss's imported drawing!
                Image(systemName: "server.rack")
                    .font(.system(size: 80))
                    .padding()
                
                Text("Health: \(gameState.boss.health) / 100")
                    .font(.title2)
                ProgressView(value: Double(gameState.boss.health), total: 100)
                    .progressViewStyle(.linear)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(15)

            // --- GAME MESSAGE ---
            Text(gameState.gameMessage)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            // --- PLAYERS ---
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(gameState.players) { player in
                        PlayerView(player: player, gameState: gameState)
                    }
                }
                .padding()
            }
            
            // --- BOSS TURN BUTTON ---
            if gameState.currentPlayerTurn == gameState.boss.id {
                Button("Boss's Turn") {
                    gameState.bossAttack()
                }
                .font(.title2.bold())
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

/// A sub-view for a single player
struct PlayerView: View {
    let player: Player
    @ObservedObject var gameState: GameState
    
    // Check if it's this player's turn
    var isMyTurn: Bool {
        gameState.currentPlayerTurn == player.id
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(player.name)
                .font(.title3.bold())
            
            // --- AVATAR ---
            // This logic tries to load the custom drawing.
            // If it can't, it shows a default icon.
            playerAvatar
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .background(Circle().fill(Color.blue.opacity(0.1)))
                .overlay(Circle().stroke(isMyTurn ? Color.yellow : Color.gray, lineWidth: 4))
            
            Text("HP: \(player.health) / 20")
            
            // --- MOVES ---
            if isMyTurn {
                ForEach(player.moves) { move in
                    Button(move.name) {
                        // Player attacks!
                        gameState.playerAttack(playerID: player.id, move: move)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            } else {
                // Show moves, but disabled
                ForEach(player.moves) { move in
                    Text(move.name)
                        .font(.caption)
                        .padding(5)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
        .shadow(radius: isMyTurn ? 10 : 0)
    }
    
    /// This helper handles converting the "drawing" Data into an Image
    var playerAvatar: Image {
        if let data = player.customAvatarData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        // Default placeholder icon
        return Image(systemName: "person.fill")
    }
}

// Helper for UIImage on macOS
#if os(macOS)
typealias UIImage = NSImage
#endif
