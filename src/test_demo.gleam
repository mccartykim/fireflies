import bencode
import gleam/io
import gleam/bit_array
import gleam/int

pub fn main() {
  // Test encode_int
  io.println("Testing encode_int:")
  let encoded_42 = bencode.encode_int(42)
  io.println("encode_int(42) = " <> bit_array.inspect(encoded_42))
  
  let encoded_neg7 = bencode.encode_int(-7)
  io.println("encode_int(-7) = " <> bit_array.inspect(encoded_neg7))
  
  // Test decode_int
  io.println("\nTesting decode_int:")
  case bencode.decode_int(<<"i42e":utf8>>) {
    Ok(#(num, rest)) -> {
      io.println("decode_int(\"i42e\") = " <> int.to_string(num) <> ", remainder: " <> bit_array.inspect(rest))
    }
    Error(e) -> io.println("Error: " <> e)
  }
  
  case bencode.decode_int(<<"i-7e":utf8>>) {
    Ok(#(num, rest)) -> {
      io.println("decode_int(\"i-7e\") = " <> int.to_string(num) <> ", remainder: " <> bit_array.inspect(rest))
    }
    Error(e) -> io.println("Error: " <> e)
  }
  
  case bencode.decode_int(<<"i123e4:spam":utf8>>) {
    Ok(#(num, rest)) -> {
      io.println("decode_int(\"i123e4:spam\") = " <> int.to_string(num) <> ", remainder: " <> bit_array.inspect(rest))
    }
    Error(e) -> io.println("Error: " <> e)
  }
}