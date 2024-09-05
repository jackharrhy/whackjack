defmodule Whack.Enemy do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :draw_pile,
    :hand,
    :hand_value,
    :discard_pile,
    :health
  ]

  alias Whack.Card

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t(),
          draw_pile: [Card.t()],
          hand: [Card.t()],
          hand_value: integer(),
          discard_pile: [Card.t()],
          health: integer()
        }

  @art [
    "👹",
    "👾",
    "🤖",
    "👻",
    "👽",
    "👿",
    "💀",
    "🧟‍♂️",
    "🧟‍♀️",
    "🧛‍♂️",
    "🧛‍♀️",
    "🧜‍♂️",
    "🧜‍♀️",
    "🧞‍♂️",
    "🧞‍♀️"
  ]

  @spec new(String.t(), String.t(), integer()) :: t()
  def new(id, name, health) do
    random_art = Enum.random(@art)

    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: random_art,
      draw_pile: [],
      hand: [],
      hand_value: 0,
      discard_pile: [],
      health: health
    })
  end
end

defimpl String.Chars, for: Whack.Enemy do
  def to_string(enemy) do
    "#{enemy.name} #{enemy.art}"
  end
end
