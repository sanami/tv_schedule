defmodule TvSchedule.Application do
  use Application

  @impl true
  def start(_type, _args) do
    IO.puts "TvSchedule.Application.start"
    children = [
      {Plug.Cowboy, plug: TvSchedule.Web, scheme: :http, port: 8080}
    ]

    opts = [strategy: :one_for_one, name: TvSchedule.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
