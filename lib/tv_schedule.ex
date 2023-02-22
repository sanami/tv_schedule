defmodule TvSchedule do
  @host URI.parse("https://tv.mail.ru")
  @ignore_names ["Әзіл студио", "31 Әзіл"]

  def get_channel(channel) do
    url = URI.merge(@host, "/astana/channel/#{channel}/")
    %{status_code: 200, body: body} = HTTPoison.get! url

    File.mkdir_p("tmp")
    File.write("tmp/#{channel}.html", body)

    body
  end

  def process_item(time, name, today) do
    time = Time.from_iso8601!("#{time}:00")
    time_attrs = time |> Map.from_struct |> Map.delete(:calendar)

    date_time = Map.merge(today, time_attrs)
    date_time = if time.hour < 5 do

      DateTime.add(date_time, 60*60*24, :second) #TODO :day
    else
      date_time
    end

    %{ time: date_time, name: name }
  end

  def parse_channel(html, today \\ DateTime.utc_now) do
    {:ok, doc} = Floki.parse_document(html)

    Floki.find(doc, ".p-programms__item > .p-programms__item__inner")
    |> Enum.map(fn (item_el) ->
        time = Floki.find(item_el, ".p-programms__item__time-value") |> Floki.text
        name = Floki.find(item_el, ".p-programms__item__name-link") |> Floki.text

        if String.length(time) > 0 do
          process_item(time, name, today)
        end
      end)
    |> Enum.filter(&is_map/1)
    |> Enum.chunk_every(2,1)
    |> Enum.map(fn
        [item] -> Map.put(item, :duration, 0)
        [item, next_item]->
          duration = DateTime.diff(next_item.time, item.time, :second) / 60 #TODO :minute

          Map.put(item, :duration, duration)
      end)
  end

  def filter_items(items) do
    Enum.filter(items, fn item ->
      ((item.time.hour in 19..23) || (item.time.hour in 0..2)) && item.duration > 77 && !(item.name in @ignore_names)
    end)
  end

  def run do
    for channel <- [1644, 1606, 1502] do
      IO.puts channel

      get_channel(channel)
      |> parse_channel
      |> filter_items
      |> IO.inspect
    end

    :ok
  end
end
