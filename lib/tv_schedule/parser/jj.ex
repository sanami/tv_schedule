defmodule TvSchedule.Parser.JJ do
  require Logger

  def get_channel(_channel_id, date) do
    day_offset = Date.day_of_week(date) - 1
    url = "https://jjtv.kz/ru/schedule?date=#{day_offset}"
    Logger.debug "get_channel #{url}"

    %{status_code: 200, body: body} = HTTPoison.get! url

    body
  end

  def parse_channel(html, date \\ nil) do
    {:ok, doc} = Floki.parse_document(html)

    items =
      doc
      |> Floki.find("#tab-kaz .table-schedule__row")
      |> Enum.map(fn(tr_el) ->
          name = tr_el |> Floki.find(".table-schedule__name_js") |> Floki.text
          time = tr_el |> Floki.find(".table-schedule__time") |> Floki.text |> TvSchedule.process_time(date, nil, false)

          %{
            id: nil,
            name: name,
            category_id: nil,
            time: time,
            country: [],
            descr: nil,
            genre: [],
            imdb_rating: nil,
            name_eng: nil,
            year: nil
          }
        end)
      |> Enum.chunk_every(2,1)
      |> Enum.map(fn
          [item] -> Map.put(item, :duration, 0)
          [item, next_item]->
            duration = NaiveDateTime.diff(next_item.time, item.time, :second) |> div(60) #TODO :minute
            Map.put(item, :duration, duration)
        end)

    %{
      id: "jj",
      name: "Jibek Joly",
      date: date,
      items: items
    }
  end

  def load_channel(channel) do
    ignore_names = TvSchedule.Options.get(:ignore_names)

    items =
      channel.items
      |> TvSchedule.filter_items(ignore_names: ignore_names, by_time: true, min_duration: 45)

    %{channel | items: items}
  end
end
