defmodule QuizWeb.ParticipantLive do
  use Phoenix.LiveView, layout: {QuizWeb.Layouts, :app}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       room: nil,
       question: nil,
       code: "",
       name: "",
       participant_id: nil,
       error: nil
     )}
  end

  def handle_event("join", %{"code" => code, "name" => name}, socket) do
    case Quiz.Rooms.join_room(code, name) do
      {:ok, room, participant_id} ->
        if connected?(socket), do: Quiz.Rooms.subscribe(room.code)

        {:noreply,
         socket
         |> assign(
           room: room,
           participant_id: participant_id,
           code: room.code,
           name: String.trim(name),
           error: nil
         )
         |> assign_question()}

      {:error, reason} ->
        {:noreply, assign(socket, error: join_error(reason), code: code, name: name)}
    end
  end

  def handle_event("answer", %{"index" => index}, socket) do
    case Integer.parse(index) do
      {answer_index, ""} ->
        case Quiz.Rooms.submit_answer(
               socket.assigns.code,
               socket.assigns.participant_id,
               answer_index
             ) do
          {:ok, room} -> {:noreply, socket |> assign(room: room) |> assign_question()}
          {:error, _reason} -> {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info({:room_updated, room}, socket) do
    {:noreply, socket |> assign(room: room) |> assign_question()}
  end

  def render(assigns) do
    ~H"""
    <section class="card">
      <%= if @room do %>
        <h1>Hej, <%= @name %>!</h1>
        <%= if @room.status == :waiting do %>
          <p class="muted">Du är med i rum <strong><%= @room.code %></strong>. Väntar på att spelledaren startar.</p>
        <% else %>
          <%= if @room.status == :active do %>
            <h2>Fråga <%= @room.current_index + 1 %> av <%= Quiz.Questions.count() %></h2>
            <p><%= @question.text %></p>
            <p class="muted">Tid kvar: <%= Quiz.Rooms.seconds_remaining(@room) %> sekunder</p>
            <% participant = @room.participants[@participant_id] %>
            <button
              :for={{choice, index} <- Enum.with_index(@question.choices)}
              class="choice"
              phx-click="answer"
              phx-value-index={index}
              disabled={Map.has_key?(participant.answers, @room.current_index)}
            >
              <%= choice %>
            </button>
            <p :if={Map.has_key?(participant.answers, @room.current_index)} class="muted">Ditt svar är registrerat.</p>
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
        <h1>Gå med i ett quiz</h1>
        <p :if={@error} class="error"><%= @error %></p>
        <form phx-submit="join">
          <label for="code">Rumskod</label>
          <input id="code" name="code" value={@code} maxlength="6" required />
          <label for="name">Ditt namn</label>
          <input id="name" name="name" value={@name} maxlength="24" required />
          <button type="submit">Gå med</button>
        </form>
      <% end %>
    </section>
    """
  end

  defp assign_question(socket) do
    question =
      if socket.assigns.room.status == :active do
        Enum.at(Quiz.Questions.all(), socket.assigns.room.current_index)
      end

    assign(socket, question: question)
  end

  defp join_error(:room_not_found), do: "Rummet hittades inte. Kontrollera rumskoden."
  defp join_error(:invalid_name), do: "Skriv ett namn på högst 24 tecken."
  defp join_error(:name_taken), do: "Namnet används redan i det här rummet."

  defp join_error(:quiz_already_started),
    do: "Det går inte att gå med efter att quizet har startat."
end
