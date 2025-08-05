import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Bencode {
  BString(str: BitArray)
  BInt(num: Int)
  BDict(dict: Dict(String, Bencode))
  BList(lst: List(Bencode))
}

pub fn info_hash(torrent: Bencode) -> Result(BitArray, String) {
  case torrent {
    BDict(d) -> {
      case dict.get(d, "info") {
        Ok(BDict(info_d)) -> {
          let dict_bytes = encode_dict(info_d)
          Ok(crypto.hash(crypto.Sha1, dict_bytes))
        }
        _ -> Error("type error")
      }
    }
    _ -> Error("no info dict inside dict")
  }
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
  let encoded_interior =
    list.map(items, encode)
    |> bit_array.concat
  bit_array.from_string("l")
  |> bit_array.append(encoded_interior)
  |> bit_array.append(bit_array.from_string("e"))
}

pub fn encode_dict(d: Dict(String, Bencode)) -> BitArray {
  let sorted_pairs =
    dict.to_list(d)
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })

  let encoded_pairs =
    list.map(sorted_pairs, fn(pair) {
      let #(key, value) = pair
      bit_array.concat([
        encode_string(bit_array.from_string(key)),
        encode(value),
      ])
    })

  bit_array.concat([<<"d":utf8>>, bit_array.concat(encoded_pairs), <<"e":utf8>>])
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
  case input {
    <<"l":utf8, rest:bits>> -> {
      decode_list_rec(rest, [])
    }
    _ -> Error("Input doesn't start with 'l'")
  }
}

fn decode_list_rec(
  input: BitArray,
  acc: List(Bencode),
) -> Result(#(List(Bencode), BitArray), String) {
  case input {
    <<"e":utf8, rest:bits>> -> Ok(#(list.reverse(acc), rest))
    <<>> -> Error("e not found")
    _ -> {
      case decode(input) {
        Error(msg) -> Error("Error on list item: " <> msg)
        Ok(#(item, rest)) -> decode_list_rec(rest, [item, ..acc])
      }
    }
  }
}

pub fn decode_dict(
  input: BitArray,
) -> Result(#(Dict(String, Bencode), BitArray), String) {
  case input {
    <<"d":utf8, rest:bits>> -> {
      dict_value_helper(rest, dict.new())
    }
    _ -> Error("Dict missing d")
  }
}

fn dict_value_helper(
  input: BitArray,
  acc: Dict(String, Bencode),
) -> Result(#(Dict(String, Bencode), BitArray), String) {
  case input {
    <<>> -> Error("No e found")
    <<"e":utf8, rest:bits>> -> Ok(#(acc, rest))
    _ -> {
      case decode_string(input) {
        Error(_) -> Error("Key decode error")
        Ok(#(key, rest)) -> {
          case bit_array.to_string(key) {
            Error(_) -> Error("Key decode error")
            Ok(key_str) -> {
              case decode(rest) {
                Error(_) -> Error("Value decode failed")
                Ok(#(ben_value, rest)) -> {
                  let new_acc = dict.insert(acc, key_str, ben_value)
                  dict_value_helper(rest, new_acc)
                }
              }
            }
          }
        }
      }
    }
  }
}

pub fn main() {
  todo
}
