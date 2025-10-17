import argv
import gleam/dynamic
import gleam/dynamic/decode
import gleam/io
import gleam/list
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

fn cat_file(file: String) -> Nil {
  case simplifile.read(file) {
    Ok(contents) -> io.print(contents)
    Error(_) -> io.println("Error: Could not read file '" <> file <> "'")
  }
}

pub fn main() -> Nil {
  case argv.load().arguments {
    ["-"] -> {
      cat_stdin()
    }
    [] -> {
      io.println("Usage: gleamcat <file> [, <files>]")
    }
    files -> {
      list.each(files, cat_file)
    }
  }
}
