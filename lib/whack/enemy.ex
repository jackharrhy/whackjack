defmodule Whack.Enemy do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :draw_pile,
    :hand,
    :discard_pile
  ]

  alias Whack.Card

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          art: String.t(),
          draw_pile: [Card.t()],
          hand: [Card.t()],
          discard_pile: [Card.t()]
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

  @spec new(String.t(), String.t()) :: t()
  def new(id, name) do
    random_art = Enum.random(@art)

    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: random_art,
      draw_pile: [],
      hand: [],
      discard_pile: []
    })
  end
end

defimpl String.Chars, for: Whack.Enemy do
  def to_string(enemy) do
    "#{enemy.name} #{enemy.art}"
  end
end
