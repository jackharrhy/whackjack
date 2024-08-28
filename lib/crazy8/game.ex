defmodule Crazy8.Game do
  alias Crazy8.Player

  @derive Jason.Encoder
  defstruct messagdes: [],
            code: nil,
            state: :setup,
            players: []

  @max_players 4

  def new(code) do
    struct!(
      __MODULE__,
      messages: [
        "game #{code} created"
      ],
      code: code
    )
  end

  def put_game_into_state(game, state) do
    Map.put(game, :state, state)
  end

  def new_message(game, message) do
    game |> Map.put(:messages, [message | game.messages])
  end

  def add_player(game, player_id, player_name) do
    if game.state == :setup do
      if length(game.players) >= @max_players do
        {:error, :game_full}
      else
        player = Player.new(player_id, player_name)

        game =
          game
          |> Map.put(:players, game.players ++ [player])
          |> new_message("player #{player} joined")

        {:ok, game, player}
      end
    else
      {:error, :game_not_in_setup}
    end
  end

  def get_player_by_id(game, player_id) do
    player = Enum.find(game.players, fn player -> player.id == player_id end)

    if player do
      {:ok, player}
    else
      {:error, :player_not_found}
    end
  end
end
