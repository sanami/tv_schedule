defmodule TvWeb.Server do
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
end
