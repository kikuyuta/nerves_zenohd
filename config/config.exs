# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

# zenohd is only bundled for targets that have a "rootfs_overlay-<target>"
# directory with a matching binary (see lib/zenoh_rpi4/application.ex).
# Targets without one just get the common overlay, and skip starting zenohd.
config :nerves,
  :firmware,
  rootfs_overlay:
    ["rootfs_overlay", "rootfs_overlay-#{Mix.target()}"]
    |> Enum.filter(&File.dir?/1)
    |> Enum.map(&Path.expand/1)

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1766462409"

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end
