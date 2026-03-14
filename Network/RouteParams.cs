using Network.ClientRoutes;
using System.Text.Json.Serialization;

namespace Network;

[JsonPolymorphic(TypeDiscriminatorPropertyName = "$type")]
[JsonDerivedType(typeof(ReceiveMessageRouteParams), "client_receive_message_route")]
[JsonDerivedType(typeof(ScoreUpdateRouteParams), "client_score_update_route")]
[JsonDerivedType(typeof(StartGameRouteParams), "client_start_game_route")]
public abstract class RouteParams
{
}
