import SwiftUI

public struct LobbyView: View {
    
    @ObservedObject public var session: GameSession
    @State private var bossName: String = "Big Bad Boss"
    
    public init(session: GameSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Boss Battle")
                .font(.largeTitle.bold())
            
            VStack(alignment: .leading) {
                Text("Host Game (You are the Boss)").font(.headline)
                TextField("Boss Name", text: $bossName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom)
                
                Button {
                    let boss = Boss(
                        id: UUID(),
                        name: bossName,
                        cards: [GameState.healthDrain]
                    )
                    session.hostGame(boss: boss)
                } label: {
                    Text("Host")
                        .font(.title2).padding().frame(maxWidth: .infinity)
                        .background(Color.red).foregroundColor(.white).cornerRadius(10)
                }
            }
            .padding().background(Color(UIColor.systemGray5)).cornerRadius(15)

            VStack(alignment: .leading) {
                Text("Join Game (You are a Player)").font(.headline)
                
                Button {
                    session.joinGame()
                } label: {
                    Text("Join")
                        .font(.title2).padding().frame(maxWidth: .infinity)
                        .background(Color.blue).foregroundColor(.white).cornerRadius(10)
                }
            }
            .padding().background(Color(UIColor.systemGray5)).cornerRadius(15)
        }
        .padding()
    }
}
