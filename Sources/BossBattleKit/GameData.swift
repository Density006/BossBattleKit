import Foundation

public enum GameData: Codable {
    case fullGameState(GameState)
    case playerAttack(PlayerMove)
    case playerJoin(Player)
}
