defmodule Crazy8.Deck do
  alias Crazy8.Card

  @derive Jason.Encoder
  defstruct [
    :cards
  ]

  def new() do
    cards =
      for suit <- Card.suits(), value <- Card.values() do
        if value > 10 or value < 13 do
          Card.new(suit, value, :face)
        else
          Card.new(suit, value, :number)
        end
      end

    struct!(__MODULE__, %{
      cards: cards
    })
  end
end

defimpl String.Chars, for: Crazy8.Deck do
  def to_string(deck) do
    "Deck #{length(deck.cards)}"
  end
end
