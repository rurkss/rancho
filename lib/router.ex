defmodule Rancho.Router do
  use Plug.Router
  use Plug.Debugger
  require Logger

  plug(Plug.Logger, log: :debug)


  plug(:match)

  plug(:dispatch)


  get "/metrics" do
    send_resp(conn, 200, Prometheus.Format.Text.format())
  end

  match _ do

  send_resp(conn, 404, "not found")

  end
end
