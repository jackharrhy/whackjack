defmodule Whack.GameTest do
  use ExUnit.Case, async: true
  alias Whack.Game
  alias Whack.Player

  describe "start_game/2" do
    test "successfully starts the game with max players" do
      game = Game.new("ABCD")
      {:ok, game, _} = Game.add_player(game, "player1", "Alice", nil)
      {:ok, game, _} = Game.add_player(game, "player2", "Bob", nil)
      {:ok, game, _} = Game.add_player(game, "player3", "Charlie", nil)
      {:ok, game, _} = Game.add_player(game, "player4", "David", nil)

      assert game.host == "player1"
      assert game.state == :setup
      assert length(game.players) == 4

      {:ok, state_changes} = Game.start_game(game, "player1")

      assert length(state_changes) > 0
      [final_state | _] = Enum.reverse(state_changes)

      assert final_state.state == :playing
      assert length(final_state.players) == 4

      for player <- final_state.players do
        assert length(player.draw_pile) == 13
      end
    end

    test "returns error when non-host tries to start the game" do
      game = Game.new("TEST456")
      {:ok, game, _} = Game.add_player(game, "player1", "Alice", nil)
      {:ok, game, _} = Game.add_player(game, "player2", "Bob", nil)

      assert {:error, :not_host} = Game.start_game(game, "player2")
    end

    test "returns error when not enough players" do
      game = Game.new("TEST101")
      {:ok, game, _} = Game.add_player(game, "player1", "Alice", nil)
      {:ok, game, _} = Game.add_player(game, "player2", "Bob", nil)

      assert {:error, :not_enough_players} = Game.start_game(game, "player1")
    end
  end
end
