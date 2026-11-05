defmodule QuizWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :quiz

  @session_options [
    store: :cookie,
    key: "_quiz_key",
    signing_salt: "quiz-session"
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
  plug(Plug.Static, at: "/", from: :phoenix, only: ~w(phoenix.js))
  plug(Plug.Static, at: "/", from: :phoenix_live_view, only: ~w(phoenix_live_view.js))

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["*/*"]
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(QuizWeb.Router)
end
