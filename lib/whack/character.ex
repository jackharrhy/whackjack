defmodule Whack.Character do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :draw_pile,
    :hand,
    :hand_value,
    :discard_pile,
    :health,
    :turn_state
  ]

  alias Whack.Card
  alias Whack.Hand

  @type turn_state :: :hit | :stand | :busted
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t(),
          draw_pile: [Card.t()],
          hand: [Card.t()],
          hand_value: integer(),
          discard_pile: [Card.t()],
          health: integer(),
          turn_state: turn_state()
        }

  def new(module, id, name, art, opts \\ []) do
    struct!(module, %{
      id: id,
      name: name,
      art: art,
      draw_pile: [],
      hand: [],
      hand_value: 0,
      discard_pile: [],
      health: Keyword.get(opts, :health, 100),
      turn_state: :hit
    })
  end

  def perform_hit(%{turn_state: :hit, draw_pile: []}) do
    {:error, :empty_draw_pile}
  end

  def perform_hit(%{turn_state: :hit} = character) do
    [top_card | draw_pile] = character.draw_pile
    hand = [top_card | character.hand || []]
    hand_value = Hand.calculate_value_of_hand(hand)

    character =
      character
      |> Map.put(:draw_pile, draw_pile)
      |> Map.put(:hand, hand)
      |> Map.put(:hand_value, hand_value)

    character =
      if hand_value > 21 do
        Map.put(character, :turn_state, :busted)
      else
        character
      end

    {:ok, character}
  end

  def perform_hit(_character), do: {:error, :invalid_turn_state}

  def is_turn_in_state(%{turn_state: state}, state), do: :ok
  def is_turn_in_state(_, _), do: {:error, :invalid_turn_state}

  @spec can_draw_from_draw_pile(t()) :: :ok | {:error, :empty_draw_pile}
  def can_draw_from_draw_pile(%{draw_pile: []}), do: {:error, :empty_draw_pile}
  def can_draw_from_draw_pile(%{draw_pile: [_ | _]}), do: :ok

  @spec can_draw_from_draw_pile?(t()) :: boolean()
  def can_draw_from_draw_pile?(character), do: length(character.draw_pile) > 0
end
