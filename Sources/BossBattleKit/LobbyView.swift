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
            
            // --- HOST ---
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

            // --- JOIN ---
            VStack(alignment: .leading) {
                Text("Join Game (You are a Player)").font(.headline)
                
                Button {
                    session.joinGame()
                } label: {
                    Text("Search for Games")
                        .font(.title2).padding().frame(maxWidth: .infinity)
                        .background(Color.blue).foregroundColor(.white).cornerRadius(10)
                }
                
                // NEW: This is our custom list of found hosts
                if !session.foundPeers.isEmpty {
                    Text("Found Games:").font(.headline).padding(.top)
                    
                    // List all the hosts we found
                    List(session.foundPeers, id: \.self) { peer in
                        Button {
                            // Invite this host!
                            session.invitePeer(peer)
                        } label: {
                            Text(peer.displayName)
                                .font(.body.bold())
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 150) // Limit the height
                    
                } else if session.serviceBrowser != nil {
                    // This shows if we are searching but haven't found anyone
                    HStack {
                        ProgressView() // Spinning wheel
                        Text("Looking for games...")
                    }
                    .padding(.top)
                }
            }
            .padding().background(Color(UIColor.systemGray5)).cornerRadius(15)
        }
        .padding()
    }
}
