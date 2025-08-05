import bencode.{BInt, BString, BDict}
import gleam/io
import gleam/bit_array
import gleam/dict
import gleam/int

pub fn main() {
  // Test encoding a simple dict
  let d = dict.new()
    |> dict.insert("foo", BInt(42))
    |> dict.insert("bar", BString(<<"spam":utf8>>))
  
  let test_dict = BDict(d)
  let encoded = bencode.encode(test_dict)
  io.println("Encoded dict: " <> bit_array.inspect(encoded))
  
  // Decode it back
  case bencode.decode(encoded) {
    Ok(#(BDict(decoded), _)) -> {
      io.println("Decoded successfully!")
      case dict.get(decoded, "foo") {
        Ok(BInt(n)) -> io.println("foo = " <> int.to_string(n))
        _ -> io.println("foo not found or wrong type")
      }
      case dict.get(decoded, "bar") {
        Ok(BString(s)) -> {
          case bit_array.to_string(s) {
            Ok(str) -> io.println("bar = " <> str)
            _ -> io.println("bar not UTF-8")
          }
        }
        _ -> io.println("bar not found or wrong type")
      }
    }
    _ -> io.println("Failed to decode")
  }
  
  // Test empty dict
  let empty = BDict(dict.new())
  let encoded_empty = bencode.encode(empty)
  io.println("\nEmpty dict: " <> bit_array.inspect(encoded_empty))
  
  // Test key ordering - "zoo" should come after "apple" 
  let ordered = dict.new()
    |> dict.insert("zoo", BInt(1))
    |> dict.insert("apple", BInt(2))
  let encoded_ordered = bencode.encode(BDict(ordered))
  io.println("\nDict with zoo and apple: " <> bit_array.inspect(encoded_ordered))
  // Should encode as d5:applei2e3:zooi1ee if sorted correctly
}