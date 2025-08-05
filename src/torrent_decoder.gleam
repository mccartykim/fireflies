import bencode.{type Bencode, BDict, BInt, BList, BString}
import gleam/bit_array
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  case simplifile.read_bits("ubuntu.torrent") {
    Error(e) -> io.println("Error reading file: " <> simplifile.describe_error(e))
    Ok(content) -> {
      case bencode.decode(content) {
        Error(e) -> io.println("Error decoding torrent: " <> e)
        Ok(#(torrent, _remainder)) -> {
          io.println("Successfully decoded torrent file!")
          io.println("=====================================\n")
          print_torrent_info(torrent)
        }
      }
    }
  }
}

fn print_torrent_info(torrent: Bencode) {
  case torrent {
    BDict(d) -> {
      // Print announce URL (tracker)
      case dict.get(d, "announce") {
        Ok(BString(url)) -> {
          case bit_array.to_string(url) {
            Ok(url_str) -> io.println("Tracker URL: " <> url_str)
            Error(_) -> io.println("Tracker URL: <binary data>")
          }
        }
        _ -> Nil
      }
      
      // Print creation date
      case dict.get(d, "creation date") {
        Ok(BInt(timestamp)) -> {
          io.println("Creation timestamp: " <> int.to_string(timestamp))
        }
        _ -> Nil
      }
      
      // Print created by
      case dict.get(d, "created by") {
        Ok(BString(creator)) -> {
          case bit_array.to_string(creator) {
            Ok(creator_str) -> io.println("Created by: " <> creator_str)
            Error(_) -> Nil
          }
        }
        _ -> Nil
      }
      
      // Print comment if present
      case dict.get(d, "comment") {
        Ok(BString(comment)) -> {
          case bit_array.to_string(comment) {
            Ok(comment_str) -> io.println("Comment: " <> comment_str)
            Error(_) -> Nil
          }
        }
        _ -> Nil
      }
      
      io.println("")
      
      // Print info dictionary details
      case dict.get(d, "info") {
        Ok(BDict(info)) -> print_info_dict(info)
        _ -> io.println("No info dictionary found")
      }
    }
    _ -> io.println("Torrent file is not a dictionary!")
  }
}

fn print_info_dict(info: dict.Dict(String, Bencode)) {
  io.println("=== File Information ===")
  
  // Get piece length
  case dict.get(info, "piece length") {
    Ok(BInt(piece_len)) -> {
      io.println("Piece length: " <> format_bytes(piece_len))
    }
    _ -> Nil
  }
  
  // Get pieces hash length
  case dict.get(info, "pieces") {
    Ok(BString(pieces)) -> {
      let num_pieces = bit_array.byte_size(pieces) / 20
      io.println("Number of pieces: " <> int.to_string(num_pieces))
    }
    _ -> Nil
  }
  
  // Check if single file or multi-file
  case dict.get(info, "name") {
    Ok(BString(name)) -> {
      case bit_array.to_string(name) {
        Ok(name_str) -> {
          io.println("\nTorrent name: " <> name_str)
          
          // Single file mode - has 'length' field
          case dict.get(info, "length") {
            Ok(BInt(length)) -> {
              io.println("File size: " <> format_bytes(length))
              io.println("Mode: Single file")
            }
            _ -> {
              // Multi-file mode - has 'files' field
              case dict.get(info, "files") {
                Ok(BList(files)) -> {
                  io.println("Mode: Multi-file")
                  io.println("Number of files: " <> int.to_string(list.length(files)))
                  io.println("\nFiles in torrent:")
                  io.println("-----------------")
                  print_files(files)
                }
                _ -> Nil
              }
              Nil
            }
          }
        }
        Error(_) -> io.println("Name: <binary data>")
      }
    }
    _ -> Nil
  }
}

fn print_files(files: List(Bencode)) {
  let _ = list.index_map(files, fn(file, index) {
    case file {
      BDict(f) -> {
        io.print(int.to_string(index + 1) <> ". ")
        
        // Get file path
        case dict.get(f, "path") {
          Ok(BList(path_parts)) -> {
            let path_str = path_parts
              |> list.filter_map(fn(part) {
                case part {
                  BString(s) -> bit_array.to_string(s)
                  _ -> Error(Nil)
                }
              })
              |> string.join("/")
            io.print(path_str)
          }
          _ -> io.print("<unknown path>")
        }
        
        // Get file length
        case dict.get(f, "length") {
          Ok(BInt(len)) -> {
            io.println(" (" <> format_bytes(len) <> ")")
          }
          _ -> io.println("")
        }
        Nil
      }
      _ -> Nil
    }
  })
  Nil
}

fn format_bytes(bytes: Int) -> String {
  case bytes {
    b if b < 1024 -> int.to_string(b) <> " B"
    b if b < 1024 * 1024 -> {
      let kb = b / 1024
      int.to_string(kb) <> " KB"
    }
    b if b < 1024 * 1024 * 1024 -> {
      let mb = b / { 1024 * 1024 }
      int.to_string(mb) <> " MB"
    }
    b -> {
      let gb = b / { 1024 * 1024 * 1024 }
      int.to_string(gb) <> " GB"
    }
  }
}