using Boggle;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Network.Converters;

class IDieJsonConverter : JsonConverter<IDie>
{
    public override IDie? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        return new SimpleDie(reader.GetString()!);
    }

    public override void Write(Utf8JsonWriter writer, IDie value, JsonSerializerOptions options)
    {
        writer.WriteStringValue(value.GetLetter());
    }
}
