defmodule ExTools do
  def hello(:run, times) do
    if times == 1 do
      :world
    else
      times
    end
  end
end
