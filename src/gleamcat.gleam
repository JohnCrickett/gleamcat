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

type Mode {
  Default
  NumberNonBlankLines
  NumberAllLines
}

pub fn main() -> Nil {
  let args = argv.load().arguments
  let not_blank_lines = list.any(args, fn(arg) { arg == "-b" })
  let number_lines = list.any(args, fn(arg) { arg == "-n" })

  let current_mode = case not_blank_lines, number_lines {
    True, True -> Error("Cannot use both -b and -n flags")
    True, False -> Ok(NumberNonBlankLines)
    False, True -> Ok(NumberAllLines)
    False, False -> Ok(Default)
  }

  case current_mode {
    Ok(mode) -> {
      let files = list.filter(args, fn(arg) { arg != "-n" && arg != "-b" })
      case files {
        ["-"] | [] -> {
          cat_stdin(mode, 1)
          Nil
        }
        ["--help"] | ["-h"] -> {
          io.println("Usage: gleamcat <file> [, <files>]")
        }
        files -> {
          let line_number = 1
          list.fold(files, line_number, fn(ln, file) {
            cat_file(mode, file, ln)
          })
          Nil
        }
      }
      Nil
    }
    Error(e) -> {
      io.println(e)
    }
  }
}

fn cat_gen(readline: fn() -> LineResult, mode: Mode, line_number: Int) -> Int {
  case readline() {
    Line(line) -> {
      case mode {
        Default -> {
          io.print(line)
          cat_gen(readline, mode, line_number + 1)
        }
        NumberNonBlankLines -> {
          case string.is_empty(string.trim(line)) {
            True -> {
              io.println("")
              cat_stdin(mode, line_number)
            }
            False -> {
              io.print(int.to_string(line_number) <> " " <> line)
              cat_gen(readline, mode, line_number + 1)
            }
          }
        }
        NumberAllLines -> {
          io.print(int.to_string(line_number) <> " " <> line)
          cat_gen(readline, mode, line_number + 1)
        }
      }
    }
    Eof -> line_number
  }
}

@external(erlang, "io", "get_line")
fn erlang_get_line(prompt: String) -> dynamic.Dynamic

fn get_line(prompt: String) -> LineResult {
  case decode.run(erlang_get_line(prompt), decode.string) {
    Ok(line) -> Line(line)
    Error(_) -> Eof
  }
}

fn get_line_from_stdin() -> LineResult {
  get_line("")
}

fn cat_stdin(mode: Mode, line_number: Int) -> Int {
  cat_gen(get_line_from_stdin, mode, line_number)
}

fn get_line_from_stream(stream: file_stream.FileStream) -> LineResult {
  case file_stream.read_line(stream) {
    Ok(line) -> Line(line)
    Error(_) -> Eof
  }
}

fn get_line_fn_for_stream(stream: file_stream.FileStream) -> fn() -> LineResult {
  fn() { get_line_from_stream(stream) }
}

fn cat_file(mode: Mode, file: String, line_number: Int) -> Int {
  case file_stream.open_read(file) {
    Ok(stream) -> cat_gen(get_line_fn_for_stream(stream), mode, line_number)
    Error(_) -> {
      io.println("Failed to open file")
      line_number
    }
  }
}
