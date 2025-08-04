import gleam/bit_array
import gleam/bytes_tree
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string

pub type Bencode {
  BString(str: BitArray)
  BInt(num: Int)
  BDict(dict: Dict(String, Bencode))
  BList(lst: List(Bencode))
}

pub fn encode(value: Bencode) -> BitArray {
  case value {
    BString(str) -> encode_string(str)
    BList(lst) -> encode_list(lst)
    BInt(int) -> encode_int(int)
    BDict(dict) -> encode_dict(dict)
  }
}

pub fn encode_string(bytes: BitArray) -> BitArray {
  let size = bit_array.byte_size(bytes)
  { int.to_string(size) <> ":" }
  |> bit_array.from_string
  |> bit_array.append(bytes)
}

pub fn encode_int(n: Int) -> BitArray {
  { "i" <> int.to_string(n) <> "e" }
  |> bit_array.from_string
}

pub fn encode_list(items: List(Bencode)) -> BitArray {
  todo
}

pub fn encode_dict(d: Dict(String, Bencode)) -> BitArray {
  todo
}

pub fn decode(input: BitArray) -> Result(#(Bencode, BitArray), String) {
  case input {
    <<"i":utf8, _rest:bits>> -> {
      use #(num, remainder) <- result.map(decode_int(input))
      #(BInt(num), remainder)
    }
    <<"l":utf8, _rest:bits>> -> {
      use #(lst, remainder) <- result.map(decode_list(input))
      #(BList(lst), remainder)
    }
    <<"d":utf8, _rest:bits>> -> {
      use #(dict, remainder) <- result.map(decode_dict(input))
      #(BDict(dict), remainder)
    }
    <<digit:8, _rest:bits>> if digit >= 48 && digit <= 57 -> {
      // ASCII '0'-'9' means it's a string
      use #(str, remainder) <- result.map(decode_string(input))
      #(BString(str), remainder)
    }
    <<>> -> Error("Empty input")
    _ -> Error("Invalid bencode: unexpected byte")
  }
}

fn slice_remainder(input: BitArray, start: Int) -> BitArray {
  let total_size = bit_array.byte_size(input)
  case start >= total_size {
    True -> <<>>
    False -> {
      case bit_array.slice(input, start, total_size - start) {
        Error(_) -> <<>>
        Ok(remainder) -> remainder
      }
    }
  }
}

pub fn decode_string(input: BitArray) -> Result(#(BitArray, BitArray), String) {
  use colon_pos <- result.try(
    find_byte(input, 58, 0)
    |> result.replace_error("Decode_string: No colon in str"),
  )
  use length_bytes <- result.try(
    bit_array.slice(input, 0, colon_pos)
    |> result.replace_error("Failed to slice length prefix"),
  )
  use length_str <- result.try(
    bit_array.to_string(length_bytes)
    |> result.replace_error("Invalid UTF-8 in length"),
  )
  use length <- result.try(
    int.parse(length_str)
    |> result.replace_error("Failed to parse length: " <> length_str),
  )
  use str_bytes <- result.try(
    bit_array.slice(input, colon_pos + 1, length)
    |> result.replace_error(
      "Failed to slice string of length " <> int.to_string(length),
    ),
  )

  let remainder = slice_remainder(input, colon_pos + 1 + length)
  Ok(#(str_bytes, remainder))
}

fn find_byte(input: BitArray, target: Int, pos: Int) -> Result(Int, Nil) {
  case input {
    <<byte:8, rest:bits>> -> {
      case byte == target {
        True -> Ok(pos)
        False -> find_byte(rest, target, pos + 1)
      }
    }
    _ -> Error(Nil)
    // Empty input, target not found
  }
}

pub fn decode_int(input: BitArray) -> Result(#(Int, BitArray), String) {
  case input {
    <<"i":utf8, rest:bits>> -> {
      use e_pos <- result.try(
        find_byte(rest, 101, 0)
        // 101 is ASCII 'e'
        |> result.replace_error("No closing 'e' found for integer"),
      )
      use num_bytes <- result.try(
        bit_array.slice(rest, 0, e_pos)
        |> result.replace_error("Failed to slice number bytes"),
      )
      use num_str <- result.try(
        bit_array.to_string(num_bytes)
        |> result.replace_error("Invalid UTF-8 in integer"),
      )
      use num <- result.try(
        int.parse(num_str)
        |> result.replace_error("Failed to parse integer: " <> num_str),
      )

      let remainder = slice_remainder(rest, e_pos + 1)
      Ok(#(num, remainder))
    }
    _ -> Error("Input does not start with 'i'")
  }
}

pub fn decode_list(
  input: BitArray,
) -> Result(#(List(Bencode), BitArray), String) {
  todo
}

pub fn decode_dict(
  input: BitArray,
) -> Result(#(Dict(String, Bencode), BitArray), String) {
  todo
}

pub fn main() {
  todo
}
