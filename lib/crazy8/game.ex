defmodule Crazy8.Game do
  alias Crazy8.Player
  alias Crazy8.Deck

  @derive Jason.Encoder
  defstruct messages: [],
            code: nil,
            state: :setup,
            players: [],
            deck: nil,
            host_id: nil

  @max_players 4

  def new(code) do
    deck = Deck.new() |> Deck.shuffle()

    struct!(
      __MODULE__,
      messages: [
        "game #{code} created"
      ],
      code: code,
      deck: deck
    )
  end

  def put_game_into_state(game, state) do
    Map.put(game, :state, state)
  end

  def new_message(game, message) do
    game |> Map.put(:messages, [message | game.messages])
  end

  def hand_size(game) do
    if length(game.players) == 2 do
      7
    else
      5
    end
  end

  def deal_hand(game, player_id) do
    {:ok, player} = get_player_by_id(game, player_id)

    if player do
      {deck, hand} = Deck.deal_hand(game.deck, hand_size(game))

      player = player |> Map.put(:hand, hand)
      player_index = get_player_index(game, player_id)

      game =
        game
        |> Map.put(:deck, deck)
        |> Map.put(:players, List.replace_at(game.players, player_index, player))
        |> new_message("player #{player.name} dealt hand")

      {:ok, game}
    else
      {:error, :player_not_found}
    end
  end

  def add_player(game, player_id, player_name) do
    if game.state == :setup do
      if length(game.players) >= @max_players do
        {:error, :game_full}
      else
        player = Player.new(player_id, player_name, [])

        game =
          if is_nil(game.host_id) do
            Map.put(game, :host_id, player_id)
          else
            game
          end

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

  def get_player_index(game, player_id) do
    Enum.find_index(game.players, fn player -> player.id == player_id end)
  end

  def is_player_host?(game, player_id) do
    player_id == game.host_id
  end
end
