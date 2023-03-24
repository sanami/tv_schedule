defmodule TvSchedule.Web do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_header("location", "/0")
    |> send_resp(301, "")
  end

  get "/:date" do
    data = ExUnit.CaptureIO.capture_io fn ->
      # TvSchedule.run(date, [1644, 1502])
      TvSchedule.run(date)
    end

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, data)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def run do
    webserver = {Plug.Cowboy, plug: TvSchedule.Web, scheme: :http, port: 3000}
    {:ok, _} = Supervisor.start_link([webserver], strategy: :one_for_one)
  end
end
