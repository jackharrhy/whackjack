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

  def shuffle(deck) do
    cards = Enum.shuffle(deck.cards)
    Map.put(deck, :cards, cards)
  end

  def deal_hand(deck, hand_size) do
    if hand_size > length(deck.cards) do
      {:error, :not_enough_cards}
    end

    {hand, cards} = Enum.split(deck.cards, hand_size)
    {Map.put(deck, :cards, cards), hand}
  end
end

defimpl String.Chars, for: Crazy8.Deck do
  def to_string(deck) do
    "Deck #{length(deck.cards)}"
  end
end
