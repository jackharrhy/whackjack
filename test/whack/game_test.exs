defmodule Whack.GameTest do
  use ExUnit.Case, async: true
  alias Whack.Game
  alias Whack.Card

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

  describe "full match" do
    test "all players hitting twice, getting 20s, ends with nothing happening" do
      {game, player1, player2, player3, player4} =
        Game.new("ABCD") |> add_four_players()

      queen_of_hearts = Card.new(:hearts, 12, :face)

      game = game |> Game.start_game(player1.id) |> get_final_state()

      players =
        game.players
        |> Enum.map(fn player ->
          %{player | draw_pile: List.duplicate(queen_of_hearts, 2)}
        end)

      enemies =
        game.enemies
        |> Enum.map(fn enemy ->
          %{enemy | draw_pile: List.duplicate(queen_of_hearts, 2)}
        end)

      game = game |> Map.put(:players, players) |> Map.put(:enemies, enemies)

      assert game.state == :playing

      player_actions = fn game, player ->
        game
        |> Game.hit(player.id)
        |> get_final_state()
        |> Game.hit(player.id)
        |> get_final_state()
        |> Game.stand(player.id)
        |> get_final_state()
      end

      game = player_actions.(game, player1)

      player1 = game.players |> Enum.at(0)
      player1_enemy = game.enemies |> Enum.at(0)

      assert player1.hand_value == 20
      assert player1_enemy.hand_value == 20

      assert player1.incoming_damage == 0
      assert player1_enemy.incoming_damage == 0

      game =
        game
        |> player_actions.(player2)
        |> player_actions.(player3)
        |> player_actions.(player4)

      assert game.turn == nil
    end
  end
end
