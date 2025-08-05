import bencode.{BDict, BInt, BString, BList}
import gleam/bit_array
import gleam/dict
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// Test basic info hash calculation
pub fn info_hash_basic_test() {
  // Create a simple torrent structure
  let info = dict.new()
    |> dict.insert("name", BString(<<"test.txt":utf8>>))
    |> dict.insert("length", BInt(1024))
    |> dict.insert("piece length", BInt(16384))
    |> dict.insert("pieces", BString(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19>>))
  
  let torrent = BDict(dict.new() |> dict.insert("info", BDict(info)))
  
  // Calculate info hash
  let result = bencode.info_hash(torrent)
  
  // Should succeed and return 20 bytes (SHA1)
  should.be_ok(result)
  case result {
    Ok(hash) -> {
      bit_array.byte_size(hash)
      |> should.equal(20)
    }
    _ -> panic
  }
}

// Test that the same info dict always produces the same hash
pub fn info_hash_deterministic_test() {
  // Create the same torrent twice
  let make_torrent = fn() {
    let info = dict.new()
      |> dict.insert("name", BString(<<"file.dat":utf8>>))
      |> dict.insert("length", BInt(5000))
    BDict(dict.new() |> dict.insert("info", BDict(info)))
  }
  
  let torrent1 = make_torrent()
  let torrent2 = make_torrent()
  
  let hash1 = bencode.info_hash(torrent1) |> should.be_ok
  let hash2 = bencode.info_hash(torrent2) |> should.be_ok
  
  hash1 |> should.equal(hash2)
}

// Test error cases
pub fn info_hash_no_info_dict_test() {
  let torrent = BDict(dict.new() |> dict.insert("announce", BString(<<"http://tracker":utf8>>)))
  
  bencode.info_hash(torrent)
  |> should.be_error
}

pub fn info_hash_not_dict_test() {
  let not_a_torrent = BList([BInt(1), BInt(2)])
  
  bencode.info_hash(not_a_torrent)
  |> should.be_error
}