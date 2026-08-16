defmodule NervesZenohd.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  # Populated per-target by the rootfs_overlay-#{Mix.target()} overlay
  # (see mix.exs). Boards without a matching zenohd build simply won't
  # have this file, and zenohd is skipped rather than crash-looping.
  @target Mix.target()
  @zenohd_bin "/usr/bin/zenohd"
  @zenohd_config "/etc/zenoh/config.json5"

  @impl true
  def start(_type, _args) do
    children = zenohd_children() ++ target_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesZenohd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp zenohd_children() do
    cond do
      @target == :host ->
        []

      File.exists?(@zenohd_bin) ->
        [
          {MuonTrap.Daemon,
           [@zenohd_bin, ["--config", @zenohd_config], [name: :zenohd_daemon]]}
        ]

      true ->
        Logger.warning(
          "#{@zenohd_bin} not found for target #{@target}; skipping zenohd startup"
        )

        []
    end
  end

  # List all child processes to be supervised
  if Mix.target() == :host do
    defp target_children() do
      [
        # Children that only run on the host during development or test.
        # In general, prefer using `config/host.exs` for differences.
        #
        # Starts a worker by calling: Host.Worker.start_link(arg)
        # {Host.Worker, arg},
      ]
    end
  else
    defp target_children() do
      [
        # Children for all targets except host
        # Starts a worker by calling: Target.Worker.start_link(arg)
        # {Target.Worker, arg},
      ]
    end
  end
end
