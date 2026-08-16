# ZenohRpi4

A Nerves app that runs [zenohd](https://github.com/eclipse-zenoh/zenoh) as a
supervised OTP child (`MuonTrap.Daemon`, see `lib/zenoh_rpi4/application.ex`)
so it starts automatically on boot.

## zenohd binaries

`zenohd` is bundled per-target via layered rootfs overlays
(`rootfs_overlay-<target>/usr/bin/zenohd`, wired up in `config/config.exs`).
Targets without a matching overlay directory boot fine but skip starting
zenohd (see the `File.exists?/1` check in `application.ex`).

Currently built and bundled for `aarch64-nerves-linux-gnu` boards only:
`rpi4`, `rpi5`, `rpi0_2`, `qemu_aarch64`.

Not yet built: `bbb`, `rpi2`, `rpi3`, `grisp2`, `osd32mp1`
(`armv7-nerves-linux-gnueabihf`), `rpi`/`rpi0` (`armv6-nerves-linux-gnueabihf`),
`mangopi_mq_pro` (`riscv64`), `x86_64` (musl). Adding one of these just means
cross-building `zenohd` for that triple and dropping it into a new
`rootfs_overlay-<target>/usr/bin/zenohd`.

The binaries were cross-built from
[eclipse-zenoh/zenoh](https://github.com/eclipse-zenoh/zenoh) @ `e096c6ba2`
using the matching `aarch64-nerves-linux-gnu` toolchain (see each target's
`nerves_defconfig` for the exact toolchain URL). The source checkout itself
isn't tracked here (see `.gitignore`) — re-clone it at that commit to rebuild.

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
