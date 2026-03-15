using Network.ClientRoutes;
using Network.ServerRoutes;
using System.Text.Json.Serialization;

namespace Network;

[JsonPolymorphic(TypeDiscriminatorPropertyName = "$type")]
[JsonDerivedType(typeof(EndGameRouteParams), "client_end_game_route")]
[JsonDerivedType(typeof(OpponentDisconnectedRouteParams), "client_opponent_disconnected_route")]
[JsonDerivedType(typeof(ReceiveMessageRouteParams), "client_receive_message_route")]
[JsonDerivedType(typeof(ScoreUpdateRouteParams), "client_score_update_route")]
[JsonDerivedType(typeof(StartGameRouteParams), "client_start_game_route")]
[JsonDerivedType(typeof(SubmitGuessRouteParams), "server_submit_guess_route")]
[JsonDerivedType(typeof(SubmitNameRouteParams), "server_submit_name_route")]
public abstract class RouteParams
{
}
