defmodule TvSchedule.Cache do
  def cache_file_path(file_id), do: "tmp/cache/#{file_id}"

  def save_cache(file_id, data) do
    File.mkdir_p("tmp/cache")

    if data && String.length(data) > 0 do
      File.write(cache_file_path(file_id), data)
    end
  end

  def load_cache(_file_id, true), do: nil

  def load_cache(file_id, false) do
    case File.read(cache_file_path(file_id)) do
      {:ok, data} -> data
      {:error, _} -> nil
    end
  end
end
