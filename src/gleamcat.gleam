import argv
import gleam/dynamic
import gleam/dynamic/decode
import gleam/io
import simplifile

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

fn cat_stdin() -> Nil {
  case get_line("") {
    Line(line) -> {
      io.print(line)
      cat_stdin()
    }
    Eof -> Nil
  }
}

pub fn main() -> Nil {
  case argv.load().arguments {
    ["-"] -> {
      cat_stdin()
    }
    [file] -> {
      case simplifile.read(file) {
        Ok(contents) -> io.println(contents)
        Error(_) -> io.println("Error: Could not read file '" <> file <> "'")
      }
    }
    _ -> io.println("Usage gleamcat <file> [, <files>]")
  }
}
