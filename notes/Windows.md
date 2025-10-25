# Windows support

This note collects the steps needed to build and link Automerge-swift when you target Swift on Windows.

## Prerequisites

- Install the [official Swift toolchain for Windows](https://www.swift.org/download/).
- Install Rust with [rustup](https://www.rust-lang.org/tools/install). The commands below assume the MSVC toolchain that ships with the Swift toolchain.
- Add the targets you need. Examples:
  ```powershell
  rustup target add x86_64-pc-windows-msvc
  rustup target add aarch64-pc-windows-msvc
  ```

## Build the Rust core

From the repository root run Cargo for the architecture you need:

```powershell
cargo build --manifest-path rust/Cargo.toml --release --target x86_64-pc-windows-msvc
```

Repeat with `aarch64-pc-windows-msvc` if you also need ARM64 binaries. The resulting static libraries are placed under:

```
rust\target\<triple>\release\uniffi_automerge.lib
```

The generated header `automergeFFI.h` and module map are already checked in at `Sources\_CAutomergeUniffi\include`, so no extra steps are required there.

## Link the library from SwiftPM

Automerge-swift exposes the FFI header through the system library target `_CAutomergeUniffi`. You only need to point the Swift compiler at the `.lib` you built. One way to do this is to pass the absolute path directly to the linker:

```powershell
swift build ^
  -Xlinker "C:\path\to\automerge-swift\rust\target\x86_64-pc-windows-msvc\release\uniffi_automerge.lib"
```

Alternatively you can add the directory to the search path and rely on the default library name:

```powershell
swift build `
  -Xswiftc -L"C:\path\to\automerge-swift\rust\target\x86_64-pc-windows-msvc\release" `
  -Xswiftc -luniffi_automerge
```

Use the Windows PowerShell escape character that matches your shell (`^` for `cmd`, `` ` `` for PowerShell) or place the command on a single line.

Once the `.lib` is visible to the linker, you can run `swift test` or integrate the package in another SwiftPM project the same way you would on Apple platforms.

## Troubleshooting

- If the linker cannot find `uniffi_automerge.lib`, double-check the path and that you built the matching architecture triple for your Swift toolchain.
- When switching between debug and release builds make sure you pass the library from the corresponding directory (`debug` vs `release`).
- Swift on Windows uses the MSVC toolchain. Avoid linking libraries compiled for the GNU ABI (`*-windows-gnu`) as they are not compatible.

