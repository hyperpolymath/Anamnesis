import Config

# For development, we disable any cache and enable
# debugging and code reloading.
config :anamnesis, AnamnesisWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "development_secret_key_base_change_in_production_!!!!!!!!!!!!!!!!!!",
  watchers: []

# Enable dev routes for dashboard and mailbox
config :anamnesis, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
