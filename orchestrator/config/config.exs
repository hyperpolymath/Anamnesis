import Config

# Anamnesis core configuration
config :anamnesis,
  parser_port_path: Path.expand("../../parser/_build/default/bin/parser_port.exe", __DIR__),
  lambda_prolog_path: Path.expand("../../reasoning/_build/default/bin/reasoner_port.exe", __DIR__),
  julia_port_path: Path.expand("../../learning/port_interface.jl", __DIR__),
  virtuoso_endpoint: "http://localhost:8890/sparql",
  parser_pool_size: 4

# Phoenix configuration
config :anamnesis, AnamnesisWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: AnamnesisWeb.ErrorHTML, json: AnamnesisWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Anamnesis.PubSub,
  live_view: [signing_salt: "CHANGE_ME_IN_PROD"]

# Configure esbuild
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing
config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"
