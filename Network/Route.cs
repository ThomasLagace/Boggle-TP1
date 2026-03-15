namespace Network;

public enum Route
{
    //Client
    StartGame,
    OpponentDisconnected,
    ScoreUpdate,
    ReceiveMessage,
    EndGame,
    //Serveur
    SubmitName,
    SubmitGuess
}