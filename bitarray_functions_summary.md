# Gleam Standard Library BitArray Functions Summary

## BitArray Module (`gleam/bit_array`)

### String ↔ BitArray Conversion

1. **`from_string(x: String) -> BitArray`**
   - Converts a UTF-8 String type into a BitArray
   - Example: `bit_array.from_string("Hello")`

2. **`to_string(bits: BitArray) -> Result(String, Nil)`**
   - Converts a bit array to a string
   - Returns an error if the bit array is invalid UTF-8 data
   - Example: `bit_array.to_string(my_bit_array)`

### BitArray Manipulation

1. **`append(first: BitArray, second: BitArray) -> BitArray`**
   - Creates a new bit array by joining two bit arrays

2. **`slice(from: BitArray, at position: Int, take length: Int) -> Result(BitArray, Nil)`**
   - Extracts a sub-section of a bit array
   - The slice will start at given position and continue up to specified length
   - A negative length can be used to extract bytes at the end of a bit array
   - Runs in constant time

3. **`pad_to_bytes(x: BitArray) -> BitArray`**
   - Pads a bit array with zeros so that it is a whole number of bytes

### Encoding and Decoding

1. **`base16_encode(input: BitArray) -> String`**
   - Encodes a BitArray into a base 16 encoded string
   - If the bit array doesn't contain a whole number of bytes, it's padded with zero bits

2. **`base16_decode(input: String) -> Result(BitArray, Nil)`**
   - Decodes a base 16 encoded string into a BitArray

3. **`base64_encode(input: BitArray) -> String`**
   - Encodes a BitArray into a base 64 encoded string
   - If the bit array doesn't contain a whole number of bytes, it's padded with zero bits

4. **`base64_decode(input: String) -> Result(BitArray, Nil)`**
   - Decodes a base 64 encoded string into a BitArray

5. **`base64_url_encode(input: BitArray) -> String`**
   - Encodes a BitArray into a base 64 encoded string with URL and filename safe alphabet

6. **`base64_url_decode(input: String) -> Result(BitArray, Nil)`**
   - Decodes a base 64 encoded string with URL and filename safe alphabet into a BitArray

### Validation and Inspection

1. **`is_utf8(bits: BitArray) -> Bool`**
   - Tests to see whether a bit array is valid UTF-8

2. **`inspect(input: BitArray) -> String`**
   - Converts a bit array to a string containing the decimal value of each byte
   - Use this over string.inspect when you have a bit array you want printed in the array syntax even if it is valid UTF-8

3. **`starts_with(bits: BitArray, prefix: BitArray) -> Bool`**
   - Checks whether the first BitArray starts with the second one

## Usage Examples

```gleam
import gleam/bit_array
import gleam/io

pub fn demo() {
  // String to BitArray
  let hello_bits = bit_array.from_string("Hello, World!")
  
  // BitArray to String
  case bit_array.to_string(hello_bits) {
    Ok(str) -> io.println(str)  // Prints: Hello, World!
    Error(_) -> io.println("Invalid UTF-8")
  }
  
  // Base64 encoding
  let encoded = bit_array.base64_encode(hello_bits)
  io.println(encoded)  // Prints: SGVsbG8sIFdvcmxkIQ==
  
  // Base64 decoding
  case bit_array.base64_decode(encoded) {
    Ok(decoded) -> {
      case bit_array.to_string(decoded) {
        Ok(str) -> io.println(str)  // Prints: Hello, World!
        Error(_) -> io.println("Invalid UTF-8")
      }
    }
    Error(_) -> io.println("Invalid base64")
  }
  
  // Inspect for debugging
  let debug_output = bit_array.inspect(hello_bits)
  io.println(debug_output)  // Prints: <<72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33>>
}
```

## Notes

- The BitArray type was previously called BitString in older versions of Gleam
- The `gleam/bit_string` module has been deprecated in favor of `gleam/bit_array`
- BitArrays are particularly useful for working with binary protocols, file I/O, and encoding/decoding operations