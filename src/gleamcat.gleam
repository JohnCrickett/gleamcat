import argv
import file_streams/file_stream
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import gleam/string

type LineResult {
  Line(String)
  Eof
}

@external(erlang, "io", "get_line")
fn erlang_get_line(prompt: String) -> dynamic.Dynamic

fn get_line(prompt: String) -> LineResult {
  case decode.run(erlang_get_line(prompt), decode.string) {
    Ok(line) -> Line(line)
    Error(_) -> Eof
  }
}

fn cat_stdin(number_lines: Bool, not_blank_lines: Bool, line_number: Int) -> Nil {
  case get_line("") {
    Line(line) -> {
      case not_blank_lines {
        True -> {
          case string.is_empty(string.trim(line)) {
            True -> {
              io.println("")
              cat_stdin(number_lines, not_blank_lines, line_number)
            }
            False -> {
              io.print(int.to_string(line_number) <> " " <> line)
              cat_stdin(number_lines, not_blank_lines, line_number + 1)
            }
          }
        }
        False -> {
          case number_lines {
            True -> io.print(int.to_string(line_number) <> " " <> line)
            False -> io.print(line)
          }
          cat_stdin(number_lines, not_blank_lines, line_number + 1)
        }
      }
    }
    Eof -> Nil
  }
}

fn get_file_line(stream: file_stream.FileStream) -> LineResult {
  case file_stream.read_line(stream) {
    Ok(line) -> Line(line)
    Error(_) -> Eof
  }
}

fn cat_file_contents(
  number_lines: Bool,
  not_blank_lines: Bool,
  line_number: Int,
  stream: file_stream.FileStream,
) -> Nil {
  case get_file_line(stream) {
    Line(line) -> {
      case not_blank_lines {
        True -> {
          case string.is_empty(string.trim(line)) {
            True -> {
              io.println("")
              cat_file_contents(
                number_lines,
                not_blank_lines,
                line_number,
                stream,
              )
            }
            False -> {
              io.print(int.to_string(line_number) <> " " <> line)
              cat_file_contents(
                number_lines,
                not_blank_lines,
                line_number + 1,
                stream,
              )
            }
          }
        }
        False -> {
          case number_lines {
            True -> {
              io.print(int.to_string(line_number) <> " " <> line)
              cat_file_contents(
                number_lines,
                not_blank_lines,
                line_number + 1,
                stream,
              )
            }
            False -> {
              io.print(line)
              cat_file_contents(
                number_lines,
                not_blank_lines,
                line_number + 1,
                stream,
              )
            }
          }
        }
      }
    }
    Eof -> Nil
  }
}

fn cat_file(number_lines: Bool, not_blank_lines: Bool, file: String) -> Nil {
  case file_stream.open_read(file) {
    Ok(stream) -> cat_file_contents(number_lines, not_blank_lines, 1, stream)
    Error(_) -> io.println("Failed to open file")
  }
}

pub fn main() -> Nil {
  let args = argv.load().arguments
  let not_blank_lines = list.any(args, fn(arg) { arg == "-b" })
  let number_lines = list.any(args, fn(arg) { arg == "-n" })

  case number_lines && not_blank_lines {
    True -> {
      io.println("Error can't have both options set")
    }
    False -> {
      let files = list.filter(args, fn(arg) { arg != "-n" && arg != "-b" })
      case files {
        ["-"] | [] -> {
          cat_stdin(number_lines, not_blank_lines, 1)
        }
        ["--help"] | ["-h"] -> {
          io.println("Usage: gleamcat <file> [, <files>]")
        }
        files -> {
          list.each(files, fn(file) {
            cat_file(number_lines, not_blank_lines, file)
          })
        }
      }
    }
  }
}
