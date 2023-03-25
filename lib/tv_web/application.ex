defmodule TvWeb.Application do
  use Application

  @impl true
  def start(_type, _args) do
    IO.puts "TvWeb.Application.start"
    children = [
      {Plug.Cowboy, plug: TvWeb.Server, scheme: :http, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: TvWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
