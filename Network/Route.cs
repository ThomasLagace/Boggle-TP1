namespace Network;

public enum Route
{
    //Client
    StartGame,
    ScoreUpdate,
    ReceiveMessage,
    EndGame,
    //Serveur
    SubmitName,
    SubmitGuess
}