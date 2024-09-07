defmodule Whack.GameTest do
  use ExUnit.Case, async: true
  alias Whack.Game

  def add_4_players_to_game(game) do
    {:ok, game, _player} = Game.add_player(game, "player1", "Alice", nil)
    {:ok, game, _player} = Game.add_player(game, "player2", "Bob", nil)
    {:ok, game, _player} = Game.add_player(game, "player3", "Charlie", nil)
    {:ok, game, _player} = Game.add_player(game, "player4", "David", nil)
    game
  end

  describe "start_game/2" do
    test "successfully starts the game with max players" do
      game = Game.new("ABCD") |> add_4_players_to_game()

      assert game.host == "player1"
      assert game.state == :setup
      assert length(game.players) == 4

      {:ok, state_changes} = Game.start_game(game, "player1")

      assert length(state_changes) > 0
      [{_, final_state} | _] = Enum.reverse(state_changes)

      assert final_state.state == :playing
      assert length(final_state.players) == 4

      for player <- final_state.players do
        assert length(player.draw_pile) == 13
      end
    end

    test "returns error when non-host tries to start the game" do
      game = Game.new("ABCD")
      {:ok, game, _} = Game.add_player(game, "player1", "Alice", nil)
      {:ok, game, _} = Game.add_player(game, "player2", "Bob", nil)

      assert {:error, :not_host} = Game.start_game(game, "player2")
    end

    test "returns error when not enough players" do
      game = Game.new("ABCD")
      {:ok, game, _} = Game.add_player(game, "player1", "Alice", nil)
      {:ok, game, _} = Game.add_player(game, "player2", "Bob", nil)

      assert {:error, :not_enough_players} = Game.start_game(game, "player1")
    end
  end

  def get_final_state({:ok, state_changes}) do
    state_changes |> Enum.at(-1) |> elem(1)
  end

  def add_four_players(game) do
    {:ok, game, player1} = Game.add_player(game, "player1", "Alice", nil)
    {:ok, game, player2} = Game.add_player(game, "player2", "Bob", nil)
    {:ok, game, player3} = Game.add_player(game, "player3", "Charlie", nil)
    {:ok, game, player4} = Game.add_player(game, "player4", "David", nil)
    {game, player1, player2, player3, player4}
  end

  describe "hit/2" do
    test "performs a hit" do
      {game, player1, _player2, _player3, _player4} =
        Game.new("ABCD") |> add_four_players()

      game = game |> Game.start_game(player1.id) |> get_final_state()

      assert game.state == :playing

      game = game |> Game.hit(player1.id) |> get_final_state()

      assert game.state == :playing
    end
  end
end
