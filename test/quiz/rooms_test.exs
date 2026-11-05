defmodule Quiz.RoomsTest do
  use ExUnit.Case, async: false

  alias Quiz.{Questions, Rooms}

  test "a host can start the five-question quiz and participants earn live points" do
    assert Questions.count() == 5
    assert {:ok, room} = Rooms.create_room()
    assert {:ok, _room, participant_id} = Rooms.join_room(room.code, "  Ada  ")
    assert {:ok, active_room} = Rooms.start_quiz(room.code)
    assert active_room.status == :active

    correct_answer = Enum.at(Questions.all(), 0).correct_answer
    assert {:ok, answered_room} = Rooms.submit_answer(room.code, participant_id, correct_answer)
    assert [%{name: "Ada", score: 1}] = Rooms.scoreboard(answered_room)
    assert {:error, :already_answered} = Rooms.submit_answer(room.code, participant_id, 0)
  end

  test "joining validates the room, name, and duplicate names" do
    assert {:error, :room_not_found} = Rooms.join_room("missing", "Ada")
    assert {:ok, room} = Rooms.create_room()
    assert {:error, :invalid_name} = Rooms.join_room(room.code, " ")
    assert {:ok, _room, _id} = Rooms.join_room(room.code, "Ada")
    assert {:error, :name_taken} = Rooms.join_room(room.code, "ada")
  end

  test "the timer advances the active question" do
    assert {:ok, room} = Rooms.create_room()
    assert :ok = Rooms.subscribe(room.code)
    assert {:ok, _room} = Rooms.start_quiz(room.code)
    assert_receive {:room_updated, %{status: :active, current_index: 0}}

    :sys.replace_state(Quiz.Rooms, fn state ->
      put_in(state.rooms[room.code].deadline_at, System.monotonic_time(:second) - 1)
    end)

    send(Process.whereis(Quiz.Rooms), {:tick, room.code})
    assert_receive {:room_updated, %{status: :active, current_index: 1}}
  end
end
