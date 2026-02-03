# Dev Container Setup

This dev container provides a complete development environment for the Scheme compiler project.

## Included Tools

- **OCaml 4.14** - For compiling `compiler.ml`
- **NASM** - For assembling x86-64 assembly files
- **GCC** - For linking object files
- **Make** - For building executables
- **opam** - OCaml package manager

## Usage

1. Open the project in VS Code
2. When prompted, click "Reopen in Container"
3. Or use Command Palette: `Dev Containers: Reopen in Container`

## Building

Once in the container, you can:

- Compile OCaml code: `ocamlc -c compiler.ml`
- Build assembly: `make -f testing/makefile t1`
- Run tests: `./testing/t1`

## Notes

- The container uses Ubuntu 22.04 as the base
- OCaml packages are managed via opam
- All tools are installed automatically when the container is created
