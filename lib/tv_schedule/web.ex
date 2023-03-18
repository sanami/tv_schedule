defmodule TvSchedule.Web do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    data = ExUnit.CaptureIO.capture_io fn ->
      TvSchedule.run
    end

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, data)
  end

  def run do
    webserver = {Plug.Cowboy, plug: TvSchedule.Web, scheme: :http, port: 3000}
    {:ok, _} = Supervisor.start_link([webserver], strategy: :one_for_one)
  end
end
