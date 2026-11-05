defmodule QuizWeb.Layouts do
  use Phoenix.Component

  def app(assigns) do
    ~H"""
    <!doctype html>
    <html lang="sv">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>Quizlab</title>
        <style>
          :root { font-family: system-ui, sans-serif; color: #172033; background: #f3f6fb; }
          body { margin: 0; }
          main { max-width: 760px; margin: 3rem auto; padding: 0 1rem; }
          .card { background: white; border-radius: 1rem; padding: 2rem; box-shadow: 0 8px 30px #17203312; }
          h1, h2 { margin-top: 0; }
          button, input { font: inherit; padding: .75rem 1rem; border-radius: .5rem; }
          button { border: 0; color: white; background: #4255d4; cursor: pointer; margin: .25rem; }
          button:disabled { background: #aab1c5; cursor: not-allowed; }
          input { border: 1px solid #cbd2e1; margin: .25rem; }
          .muted { color: #64708a; }
          .error { color: #b42318; }
          .choice { display: block; width: 100%; text-align: left; }
          .scoreboard { padding-left: 1.5rem; }
          .room-code { font-size: 2rem; letter-spacing: .15em; font-weight: 700; }
        </style>
      </head>
      <body>
        <main><%= @inner_content %></main>
        <script src="/phoenix.js"></script>
        <script src="/phoenix_live_view.js"></script>
        <script>
          const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
          const liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
            params: { _csrf_token: csrfToken }
          });
          liveSocket.connect();
        </script>
      </body>
    </html>
    """
  end
end
