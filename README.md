# NervesZenohd

A Nerves app that runs [zenohd](https://github.com/eclipse-zenoh/zenoh) as a
supervised OTP child so it starts automatically on boot — same mechanism on
every board, only the pre-built `zenohd` binary differs per target's
architecture/libc triple.

## How auto-start works (common to every target)

- `lib/nerves_zenohd/application.ex` starts `zenohd` via `MuonTrap.Daemon` as an
  OTP-supervised child (`/usr/bin/zenohd --config /etc/zenoh/config.json5`).
  If `/usr/bin/zenohd` isn't present on the target, it logs a warning and
  skips starting it instead of crash-looping — so a board without a matching
  binary still boots normally.
- `config/config.exs` merges `rootfs_overlay/` (common files: `etc/zenoh/config.json5`)
  with `rootfs_overlay-#{Mix.target()}/` (per-target: `usr/bin/zenohd`), keeping
  only overlay directories that actually exist on disk.
- The `zenohd` binaries were cross-built from
  [eclipse-zenoh/zenoh](https://github.com/eclipse-zenoh/zenoh) @ `e096c6ba2`.
  That source checkout isn't tracked here (see `.gitignore`) — re-clone it at
  that commit to rebuild any of the binaries below.

Bundled so far: `bbb` (armv7, cross-built and verified on real hardware —
see below), `rpi2` (armv7, same toolchain triple as bbb — see below).

Not built: `rpi3`, `grisp2`, `osd32mp1` (armv7 — same triple as bbb/rpi2,
reusing that binary would work, but there was no actual need for those
targets, so no overlay dir was created for them). Also not built: `rpi4`,
`rpi5`, `rpi0_2`, `qemu_aarch64` (aarch64), `rpi`/`rpi0` (armv6),
`mangopi_mq_pro` (riscv64), `x86_64` (musl).

Note: unlike `nerves_toolchain_*`/`nerves_system_*`, `mix deps.get`/`mix firmware`
never fetch `zenohd` for you — it has nothing to do with Nerves' own toolchain
or system packages. Every `rootfs_overlay-<target>/usr/bin/zenohd` here was
placed there manually (copied or cross-built), and a new target needs the
same treatment before it'll actually run zenohd.

## RPi2B (`armv7-nerves-linux-gnueabihf`)

`nerves_system_rpi2` uses the exact same toolchain triple as `nerves_system_bbb`
(`nerves_toolchain_armv7_nerves_linux_gnueabihf`), so no separate cross-build
was needed — the `bbb` binary was simply copied into
`rootfs_overlay-rpi2/usr/bin/zenohd` as-is.

```sh
MIX_TARGET=rpi2 mix deps.get   # downloads nerves_toolchain_armv7_nerves_linux_gnueabihf + nerves_system_rpi2
MIX_TARGET=rpi2 mix firmware   # bundles rootfs_overlay/ + rootfs_overlay-rpi2/
MIX_TARGET=rpi2 mix burn       # or mix upload for an existing device
```

## BeagleBone Black (`armv7-nerves-linux-gnueabihf`)

BBB needs a 32-bit armv7 hard-float binary — a different triple from the
aarch64 boards above, so `zenohd` had to be cross-built from source instead
of reused.

1. **Install Rust + the armv7 target** (nothing Rust-related was on this
   machine beforehand):
   ```sh
   brew install rustup
   rustup-init -y --default-toolchain stable --profile minimal   # or `rustup toolchain install stable`
   rustup target add armv7-unknown-linux-gnueabihf
   ```
2. **Fetch the Nerves toolchain for BBB** — this is what actually links the
   binary, so it matches the exact glibc/kernel headers the BBB Nerves system
   ships (not a generic armv7 cross toolchain):
   ```sh
   MIX_TARGET=bbb mix deps.get
   # downloads nerves_toolchain_armv7_nerves_linux_gnueabihf to ~/.nerves/artifacts/
   ```
3. **Point cargo at that toolchain's gcc/ar** for the `armv7-unknown-linux-gnueabihf`
   Rust target, appended to `zenoh/.cargo/config.toml` (this file isn't tracked —
   `zenoh/` is a gitignored vendored checkout):
   ```toml
   [target.armv7-unknown-linux-gnueabihf]
   linker = "/Users/<you>/.nerves/artifacts/nerves_toolchain_armv7_nerves_linux_gnueabihf-darwin_arm-13.2.0/bin/armv7-nerves-linux-gnueabihf-gcc"
   ar     = "/Users/<you>/.nerves/artifacts/nerves_toolchain_armv7_nerves_linux_gnueabihf-darwin_arm-13.2.0/bin/armv7-nerves-linux-gnueabihf-ar"
   ```
4. **Cross-build just the `zenohd` binary** from the vendored `zenoh/` checkout:
   ```sh
   cd zenoh
   cargo build --release --bin zenohd --target armv7-unknown-linux-gnueabihf
   # Finished `release` profile [optimized] target(s) in 3m 20s
   ```
5. **Verify the architecture and drop it into the overlay**:
   ```sh
   file target/armv7-unknown-linux-gnueabihf/release/zenohd
   # ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically
   # linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 5.4.255
   mkdir -p ../rootfs_overlay-bbb/usr/bin
   cp target/armv7-unknown-linux-gnueabihf/release/zenohd ../rootfs_overlay-bbb/usr/bin/zenohd
   ```
6. **Build and check the firmware** the same way as any other target:
   ```sh
   MIX_TARGET=bbb mix deps.get
   MIX_TARGET=bbb mix firmware   # Copying rootfs_overlay: .../rootfs_overlay-bbb
   MIX_TARGET=bbb mix burn       # or mix upload for an existing device
   ```

Verified by unzipping the built `.fw` (it's a zip archive: `data/rootfs.img` is
a squashfs image), extracting `usr/bin/zenohd` with `unsquashfs`, and checking
its architecture with `file` — confirmed 32-bit ARM/EABI5, not the aarch64 one.

Host note: building/running this app locally also needs Erlang/OTP to match
the Nerves system's OTP major version (this repo pins Erlang 28 / Elixir 1.19
via `.mise.toml`) — a host/target OTP mismatch makes `mix firmware` refuse to
build with a clear error, unrelated to the architecture work above.

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/supported-targets.html

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Elixir Slack #nerves channel: https://elixir-slack.community/
  * Elixir Discord #nerves channel: https://discord.gg/elixir
  * Source: https://github.com/nerves-project/nerves
