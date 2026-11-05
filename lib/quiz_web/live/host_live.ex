defmodule QuizWeb.HostLive do
  use Phoenix.LiveView, layout: {QuizWeb.Layouts, :app}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, room: nil)}
  end

  def handle_event("create_room", _params, socket) do
    {:ok, room} = Quiz.Rooms.create_room()
    if connected?(socket), do: Quiz.Rooms.subscribe(room.code)
    {:noreply, assign(socket, room: room)}
  end

  def handle_event("start_quiz", %{"code" => code}, socket) do
    case Quiz.Rooms.start_quiz(code) do
      {:ok, room} -> {:noreply, assign(socket, room: room)}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign(socket, room: room)}
  end

  def render(assigns) do
    ~H"""
    <section class="card">
      <%= if @room do %>
        <h1>Spelled vy?</h1>
        <p>Dela rumkoden med deltagarna:</p>
        <p class="room-code"><%= @room.code %></p>

        <%= if @room.status == :waiting do %>
          <p class="muted"><%= map_size(@room.participants) %> deltagare väntar.</p>
          <button phx-click="start_quiz" phx-value-code={@room.code}>Starta quizet</button>
        <% else %>
          <%= if @room.status == :active do %>
            <% question = Enum.at(Quiz.Questions.all(), @room.current_index) %>
            <h2>Fråga <%= @room.current_index + 1 %> av <%= Quiz.Questions.count() %></h2>
            <p><%= question.text %></p>
            <p class="muted">Tid kvar: <%= Quiz.Rooms.seconds_remaining(@room) %> sekunder</p>
          <% else %>
            <h2>Quizet är klart!</h2>
          <% end %>
        <% end %>

        <h2>Poängtavla</h2>
        <ol class="scoreboard">
          <li :for={participant <- Quiz.Rooms.scoreboard(@room)}>
            <%= participant.name %> — <%= participant.score %> p
          </li>
        </ol>
      <% else %>
        <h1>Quizlab</h1>
        <p>Starta ett quiz med fem frågor och bjud in deltagare med en rumskod.</p>
        <button phx-click="create_room">Skapa rum</button>
        <p><a href="/join">Gå med i ett quiz</a></p>
      <% end %>
    </section>
    """
  end
end
