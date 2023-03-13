defmodule TvSchedule.Parser.MR do
  require Logger

  @host URI.parse("https://tv.mail.ru")
  @region_id 378

  def get_channel(channel_id, date, force \\ false) do
    file_id = "#{channel_id}.#{date}"
    data = TvSchedule.Cache.load_cache(file_id, force)

    if data do
      data
    else
      url = URI.merge(@host, "/ajax/channel/?channel_id=#{channel_id}&date=#{date}&region_id=#{@region_id}")
      Logger.debug "get_channel #{url}"

      body = TvSchedule.get_url(url)
      TvSchedule.Cache.save_cache(file_id, body)

      body
    end
  end

  def get_item_details(item_id, force \\ false) do
    data = TvSchedule.Cache.load_cache(item_id, force)

    if data do
      data
    else
      url = URI.merge(@host, "/ajax/event/?id=#{item_id}&region_id=#{@region_id}")
      Logger.debug "get_item_details #{url}"

      body = TvSchedule.get_url(url)
      TvSchedule.Cache.save_cache(item_id, body)

      body
    end
  end

  def parse_item_details(json_str) do
    json = Jason.decode!(json_str, keys: :atoms)

    info = %{
      #participants: json.tv_event.participants,
      country: (json.tv_event[:country] || []) |> Enum.map(&(&1.title)),
      name: json.tv_event.name,
      descr: json.tv_event.descr |> TvSchedule.replace_html_entities,
      genre: (json.tv_event[:genre] || []) |> Enum.map(&(String.downcase(&1.title))),
      imdb_rating: json.tv_event |> get_in([:afisha_event, :imdb_rating]),
      name_eng: json.tv_event |> get_in([:afisha_event, :name_eng]),
      year: json.tv_event |> get_in([:year, :title])
    }

    info
  end

  def parse_channel(json_str) do
    json = Jason.decode!(json_str, keys: :atoms)

    channel_id = get_in(json, [:schedule, Access.at(0), :channel, :id])
    date = Date.from_iso8601! json.form.date.value

    # %{time: date_time, name: name, id: item_id, duration: duration}
    items = get_in(json, [:schedule, Access.at(0), :event])
    items = (items[:past] ++ items[:current])
    |> Enum.map(fn item ->
      item
      |> Map.take([:id, :name, :category_id])
      |> Map.merge(%{
          time: TvSchedule.process_time(item.start, date, channel_id),
          country: [],
          descr: nil,
          genre: [],
          imdb_rating: nil,
          name_eng: nil,
          year: nil
        })
    end)
    |> Enum.chunk_every(2,1)
    |> Enum.map(fn
        [item] -> Map.put(item, :duration, 0)
        [item, next_item]->
          duration = NaiveDateTime.diff(next_item.time, item.time, :second) |> div(60) #TODO :minute
          Map.put(item, :duration, duration)
      end)

    %{
      id: channel_id,
      name: get_in(json, [:schedule, Access.at(0), :channel, :name]),
      date: date,
      items: items
    }
  end

  def load_item(item) do
    item_details =
      try do
        item.id |> get_item_details() |> parse_item_details()
      rescue
        ex ->
          Logger.error ex
          %{}
      end

    Map.merge(item, item_details)
  end

  def load_channel(channel) do
    items =
      channel.items
      |> TvSchedule.filter_items(by_time: true, min_duration: 45)
      # |> Enum.map(fn item -> load_item(item) end)
      |> Enum.map(&Task.async(fn -> load_item(&1) end))
      |> Enum.map(&(Task.await(&1, 30_000)))

    %{channel | items: items}
  end
end
