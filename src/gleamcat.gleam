import argv
import gleam/io
import simplifile

pub fn main() -> Nil {
  case argv.load().arguments {
    [file] -> {
      case simplifile.read(file) {
        Ok(contents) -> io.println(contents)
        Error(_) -> io.println("Error: Could not read file '" <> file <> "'")
      }
    }
    _ -> io.println("Usage gleamcat <file> [, <files>]")
  }
}
