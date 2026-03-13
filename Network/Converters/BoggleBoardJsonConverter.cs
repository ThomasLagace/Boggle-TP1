using Boggle;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Network.Converters;

public class BoggleBoardJsonConverter : JsonConverter<BoggleBoard>
{
    public override BoggleBoard? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        JsonDocument json = JsonDocument.ParseValue(ref reader);
        JsonElement boardJson = json.RootElement.GetProperty("Board");
        List<List<IDie>> board = JsonSerializer.Deserialize<List<List<IDie>>>(boardJson.GetRawText(), options)!;
        return new BoggleBoard(board);
    }

    public override void Write(Utf8JsonWriter writer, BoggleBoard value, JsonSerializerOptions options)
    {
        writer.WriteStartObject();
        writer.WritePropertyName("Board");
        JsonSerializer.Serialize(writer, value.Board, options);
        writer.WriteEndObject();
    }
}
