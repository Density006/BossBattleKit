import SwiftUI

// This view just displays the game state.
public struct BossBattleView: View {
    
    public var gameState: GameState
    public var localPlayerID: UUID?
    public var onPlayerAttack: (PlayerMove) -> Void
    public var onBossAttack: () -> Void
    
    private var iAmTheBoss: Bool { localPlayerID == gameState.boss.id }
    private var isBossTurn: Bool { gameState.currentPlayerTurn == gameState.boss.id }
    
    public init(gameState: GameState, localPlayerID: UUID?, onPlayerAttack: @escaping (PlayerMove) -> Void, onBossAttack: @escaping () -> Void) {
        self.gameState = gameState
        self.localPlayerID = localPlayerID
        self.onPlayerAttack = onPlayerAttack
        self.onBossAttack = onBossAttack
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text(gameState.boss.name).font(.largeTitle.bold())
                Image(systemName: "server.rack").font(.system(size: 80)).padding()
                Text("Health: \(gameState.boss.health) / 100").font(.title2)
                ProgressView(value: Double(gameState.boss.health), total: 100)
            }
            .padding().background(Color.red.opacity(0.1)).cornerRadius(15)

            Text(gameState.gameMessage).font(.headline).padding()
                .frame(maxWidth: .infinity).background(Color.gray.opacity(0.1)).cornerRadius(10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(gameState.players) { player in
                        PlayerView(
                            player: player,
                            isMyTurn: gameState.currentPlayerTurn == player.id,
                            iAmThisPlayer: localPlayerID == player.id,
                            onPlayerAttack: onPlayerAttack
                        )
                    }
                }
                .padding()
            }
            
            if isBossTurn && iAmTheBoss {
                Button("Boss's Turn") { onBossAttack() }
                .font(.title2.bold()).padding().background(Color.red)
                .foregroundColor(.white).cornerRadius(10)
            }
        }
        .padding()
    }
}

struct PlayerView: View {
    let player: Player
    let isMyTurn: Bool
    let iAmThisPlayer: Bool
    var onPlayerAttack: (PlayerMove) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text(player.name).font(.title3.bold())
            
            playerAvatar.resizable().aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80).clipShape(Circle())
                .background(Circle().fill(Color.blue.opacity(0.1)))
                .overlay(Circle().stroke(isMyTurn ? Color.yellow : Color.gray, lineWidth: 4))
            
            Text("HP: \(player.health) / 20")
            
            if isMyTurn && iAmThisPlayer {
                ForEach(player.moves) { move in
                    Button(move.name) { onPlayerAttack(move) }
                    .font(.caption).buttonStyle(.bordered)
                }
            } else {
                ForEach(player.moves) { move in
                    Text(move.name).font(.caption).padding(5)
                    .background(Color.gray.opacity(0.2)).cornerRadius(5)
                }
            }
        }
        .padding().background(Color.blue.opacity(0.1)).cornerRadius(15)
        .shadow(radius: isMyTurn ? 10 : 0)
    }
    
    var playerAvatar: Image {
        if let data = player.customAvatarData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "person.fill")
    }
}

// Helper for UIImage on macOS
#if os(macOS)
typealias UIImage = NSImage
#endif
