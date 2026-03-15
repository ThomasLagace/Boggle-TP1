namespace Network;

public enum Route
{
    //Client
    StartGame,
    OpponnentDisconnected,
    ScoreUpdate,
    ReceiveMessage,
    EndGame,
    //Serveur
    SubmitName,
    SubmitGuess
}