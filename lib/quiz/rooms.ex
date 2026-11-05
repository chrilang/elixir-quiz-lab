defmodule Quiz.Rooms do
  use GenServer

  alias Quiz.Questions

  @tick_interval 1_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, __MODULE__))
  end

  def create_room, do: GenServer.call(__MODULE__, :create_room)

  def join_room(code, name) do
    GenServer.call(__MODULE__, {:join_room, normalize_code(code), name})
  end

  def start_quiz(code), do: GenServer.call(__MODULE__, {:start_quiz, normalize_code(code)})

  def submit_answer(code, participant_id, answer_index) do
    GenServer.call(
      __MODULE__,
      {:submit_answer, normalize_code(code), participant_id, answer_index}
    )
  end

  def subscribe(code) do
    Phoenix.PubSub.subscribe(Quiz.PubSub, topic(normalize_code(code)))
  end

  def seconds_remaining(%{status: :active, deadline_at: deadline_at}) do
    max(deadline_at - System.monotonic_time(:second), 0)
  end

  def seconds_remaining(_room), do: 0

  def scoreboard(room) do
    room.participants
    |> Map.values()
    |> Enum.sort_by(&{-&1.score, String.downcase(&1.name)})
  end

  @impl true
  def init(:ok), do: {:ok, %{rooms: %{}}}

  @impl true
  def handle_call(:create_room, _from, state) do
    code = unique_code(state.rooms)

    room = %{
      code: code,
      status: :waiting,
      current_index: 0,
      deadline_at: nil,
      participants: %{}
    }

    {:reply, {:ok, room}, put_in(state.rooms[code], room)}
  end

  def handle_call({:join_room, code, name}, _from, state) do
    with {:ok, name} <- validate_name(name),
         {:ok, room} <- fetch_room(state, code),
         :ok <- ensure_waiting(room),
         :ok <- ensure_name_available(room, name) do
      participant_id = System.unique_integer([:positive])
      participant = %{id: participant_id, name: name, score: 0, answers: %{}}
      room = put_in(room.participants[participant_id], participant)
      next_state = put_in(state.rooms[code], room)
      broadcast(room)
      {:reply, {:ok, room, participant_id}, next_state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:start_quiz, code}, _from, state) do
    with {:ok, room} <- fetch_room(state, code),
         :ok <- ensure_waiting(room) do
      room =
        room
        |> Map.put(:status, :active)
        |> Map.put(:current_index, 0)
        |> Map.put(:deadline_at, deadline())
        |> schedule_tick()

      broadcast(room)
      {:reply, {:ok, room}, put_in(state.rooms[code], room)}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:submit_answer, code, participant_id, answer_index}, _from, state) do
    with {:ok, room} <- fetch_room(state, code),
         :ok <- ensure_active(room),
         :ok <- ensure_question_open(room),
         {:ok, participant} <- fetch_participant(room, participant_id),
         :ok <- ensure_unanswered(participant, room.current_index),
         :ok <- ensure_valid_answer(answer_index) do
      question = Enum.at(Questions.all(), room.current_index)

      participant =
        participant
        |> put_in([:answers, room.current_index], answer_index)
        |> Map.update!(
          :score,
          &(&1 + if(answer_index == question.correct_answer, do: 1, else: 0))
        )

      room = put_in(room.participants[participant_id], participant)
      broadcast(room)
      {:reply, {:ok, room}, put_in(state.rooms[code], room)}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info({:tick, code}, state) do
    case Map.fetch(state.rooms, code) do
      {:ok, %{status: :active} = room} ->
        room =
          if seconds_remaining(room) == 0 do
            advance(room)
          else
            schedule_tick(room)
          end

        broadcast(room)
        {:noreply, put_in(state.rooms[code], room)}

      _ ->
        {:noreply, state}
    end
  end

  defp advance(room) do
    next_index = room.current_index + 1

    if next_index == Questions.count() do
      %{room | status: :finished, deadline_at: nil}
    else
      room
      |> Map.put(:current_index, next_index)
      |> Map.put(:deadline_at, deadline())
      |> schedule_tick()
    end
  end

  defp schedule_tick(room) do
    Process.send_after(self(), {:tick, room.code}, @tick_interval)
    room
  end

  defp deadline, do: System.monotonic_time(:second) + Questions.seconds_per_question()

  defp fetch_room(state, code) do
    case Map.fetch(state.rooms, code) do
      {:ok, room} -> {:ok, room}
      :error -> {:error, :room_not_found}
    end
  end

  defp fetch_participant(room, participant_id) do
    case Map.fetch(room.participants, participant_id) do
      {:ok, participant} -> {:ok, participant}
      :error -> {:error, :participant_not_found}
    end
  end

  defp validate_name(name) when is_binary(name) do
    name = String.trim(name)

    if name != "" and String.length(name) <= 24 do
      {:ok, name}
    else
      {:error, :invalid_name}
    end
  end

  defp validate_name(_name), do: {:error, :invalid_name}

  defp ensure_waiting(%{status: :waiting}), do: :ok
  defp ensure_waiting(_room), do: {:error, :quiz_already_started}

  defp ensure_active(%{status: :active}), do: :ok
  defp ensure_active(_room), do: {:error, :quiz_not_active}

  defp ensure_question_open(room) do
    if seconds_remaining(room) > 0, do: :ok, else: {:error, :question_closed}
  end

  defp ensure_name_available(room, name) do
    if Enum.any?(
         Map.values(room.participants),
         &(String.downcase(&1.name) == String.downcase(name))
       ) do
      {:error, :name_taken}
    else
      :ok
    end
  end

  defp ensure_unanswered(participant, question_index) do
    if Map.has_key?(participant.answers, question_index) do
      {:error, :already_answered}
    else
      :ok
    end
  end

  defp ensure_valid_answer(index) when is_integer(index) and index >= 0 and index < 4, do: :ok
  defp ensure_valid_answer(_index), do: {:error, :invalid_answer}

  defp unique_code(rooms) do
    code =
      :crypto.strong_rand_bytes(5)
      |> Base.encode32(padding: false)
      |> binary_part(0, 6)

    if Map.has_key?(rooms, code), do: unique_code(rooms), else: code
  end

  defp normalize_code(code) when is_binary(code), do: code |> String.trim() |> String.upcase()
  defp normalize_code(_code), do: ""

  defp topic(code), do: "room:#{code}"

  defp broadcast(room),
    do: Phoenix.PubSub.broadcast(Quiz.PubSub, topic(room.code), {:room_updated, room})
end
