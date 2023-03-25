defmodule TvSchedule.Parser.JJ do
  import TvSchedule.Helper

  require Logger

  def get_channel(_channel_id, date, force \\ false) do
    file_id = "jj.#{date}"
    data = TvSchedule.Cache.load_cache(file_id, force)

    cond do
      data ->
        data

      Date.beginning_of_week(Date.utc_today) <= date && date <= Date.end_of_week(Date.utc_today) ->
        day_offset = Date.day_of_week(date) - 1
        url = "https://jjtv.kz/ru/schedule?date=#{day_offset}"
        Logger.debug "get_channel #{url}"

        body = TvSchedule.get_url(url, false)
        TvSchedule.Cache.save_cache(file_id, body)

        body

      true ->
        nil
    end
  end

  def parse_channel(nil, date) do
    %{
      id: "jj",
      name: "Jibek Joly",
      date: date,
      items: []
    }
  end

  def parse_channel(html, date) do
    {:ok, doc} = Floki.parse_document(html)

    items =
      doc
      |> Floki.find("#tab-kaz .table-schedule__row")
      |> Enum.map(fn(tr_el) ->
          name = tr_el |> Floki.find(".table-schedule__name_js") |> Floki.text
          time = tr_el |> Floki.find(".table-schedule__time") |> Floki.text |> process_time(date, nil, false)

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
          [item] -> Map.put(item, :duration, 60)
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
    items =
      channel.items
      |> filter_items(by_time: true, min_duration: 45)

    %{channel | items: items}
  end
end
