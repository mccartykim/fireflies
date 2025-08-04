import bencode.{BInt, BString}
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn encode_int_positive_test() {
  bencode.encode_int(42)
  |> should.equal(<<"i42e":utf8>>)
}

pub fn encode_int_negative_test() {
  bencode.encode_int(-7)
  |> should.equal(<<"i-7e":utf8>>)
}

pub fn encode_int_zero_test() {
  bencode.encode_int(0)
  |> should.equal(<<"i0e":utf8>>)
}

pub fn encode_string_simple_test() {
  bencode.encode_string(<<"spam":utf8>>)
  |> should.equal(<<"4:spam":utf8>>)
}

pub fn encode_string_empty_test() {
  bencode.encode_string(<<>>)
  |> should.equal(<<"0:":utf8>>)
}

pub fn encode_string_with_special_chars_test() {
  bencode.encode_string(<<"hello world!":utf8>>)
  |> should.equal(<<"12:hello world!":utf8>>)
}

pub fn decode_int_positive_test() {
  bencode.decode_int(<<"i42e":utf8>>)
  |> should.equal(Ok(#(42, <<>>)))
}

pub fn decode_int_negative_test() {
  bencode.decode_int(<<"i-7e":utf8>>)
  |> should.equal(Ok(#(-7, <<>>)))
}

pub fn decode_int_with_remainder_test() {
  bencode.decode_int(<<"i42e4:spam":utf8>>)
  |> should.equal(Ok(#(42, <<"4:spam":utf8>>)))
}

pub fn decode_string_simple_test() {
  bencode.decode_string(<<"4:spam":utf8>>)
  |> should.equal(Ok(#(<<"spam":utf8>>, <<>>)))
}

pub fn decode_string_with_remainder_test() {
  bencode.decode_string(<<"4:spami42e":utf8>>)
  |> should.equal(Ok(#(<<"spam":utf8>>, <<"i42e":utf8>>)))
}

pub fn encode_then_decode_int_test() {
  let encoded = bencode.encode(BInt(123))
  bencode.decode(encoded)
  |> should.equal(Ok(#(BInt(123), <<>>)))
}

pub fn encode_then_decode_string_test() {
  let encoded = bencode.encode(BString(<<"test":utf8>>))
  bencode.decode(encoded)
  |> should.equal(Ok(#(BString(<<"test":utf8>>), <<>>)))
}
