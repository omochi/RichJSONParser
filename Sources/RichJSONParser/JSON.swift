public enum JSON {
    case null
    case boolean(Bool)
    case number(JSONNumber)
    case string(String)
    case array(JSONArray)
    case object(JSONObject)
}
