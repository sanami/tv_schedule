import Config

config :logger,
 level: :debug,
  backends: [:console]

config :tv_schedule,
  key1: "value1",
  key2: "value2"

# Application.fetch_env!(:tv_schedule, :key1)

env_file = "#{config_env()}.exs"
# IO.puts env_file
if File.exists?("config/#{env_file}"), do: import_config(env_file)
