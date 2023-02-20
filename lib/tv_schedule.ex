defmodule TvSchedule do
  @host URI.parse("https://tv.mail.ru")

  def get_channel(channel) do
    url = URI.merge(@host, "/astana/channel/#{channel}/")
    %{status_code: 200, body: body} = HTTPoison.get! url

    body
  end

  def parse_channel(html) do
    {:ok, doc} = Floki.parse_document(html)

    Floki.find(doc, ".p-programms__item > .p-programms__item__inner")
    |> Enum.map(fn (item_el) ->
        time = Floki.find(item_el, ".p-programms__item__time-value") |> Floki.text
        if String.length(time) > 0 do
          %{ time: Time.from_iso8601!(time <> ":00"),
             name: Floki.find(item_el, ".p-programms__item__name-link") |> Floki.text}
        end
      end)
    |> Enum.filter(&is_map/1)
  end

  def run do
    for channel <- [1644, 1606, 1502] do
      IO.puts channel

      get_channel(channel)
      |> parse_channel
      |> Enum.filter(fn %{time: %{hour: h}} -> (h in 18..23) || (h in 0..2) end)
      |> IO.inspect
    end

    :ok
  end
end
