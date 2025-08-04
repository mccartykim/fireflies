import bencode.{BInt, BString, BList}
import gleam/io
import gleam/bit_array
import gleam/int
import gleam/list

pub fn main() {
  // Test encoding a list
  let test_list = BList([BInt(1), BInt(2), BInt(3)])
  let encoded = bencode.encode(test_list)
  io.println("Encoded [1,2,3]: " <> bit_array.inspect(encoded))
  
  // Test decoding
  case bencode.decode(encoded) {
    Ok(#(decoded, remainder)) -> {
      io.println("Decoded successfully!")
      io.println("Remainder: " <> bit_array.inspect(remainder))
    }
    Error(e) -> io.println("Error: " <> e)
  }
  
  // Test mixed types
  let mixed = BList([BInt(42), BString(<<"spam":utf8>>)])
  let encoded_mixed = bencode.encode(mixed)
  io.println("\nEncoded [42, \"spam\"]: " <> bit_array.inspect(encoded_mixed))
  
  // Test empty list
  let empty = BList([])
  let encoded_empty = bencode.encode(empty)
  io.println("\nEncoded []: " <> bit_array.inspect(encoded_empty))
  
  // Decode empty
  case bencode.decode(<<"le":utf8>>) {
    Ok(#(BList(items), _)) -> {
      io.println("Empty list decoded, length: " <> int.to_string(list.length(items)))
    }
    _ -> io.println("Failed to decode empty list")
  }
}