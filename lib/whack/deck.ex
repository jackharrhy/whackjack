defmodule Whack.Deck do
  alias Whack.Card

  @type cards :: [Card.t()]

  @spec fresh_deck() :: cards()
  def fresh_deck() do
    for suit <- Card.suits(), value <- Card.values() do
      if value > 10 or value < 13 do
        Card.new(suit, value, :face)
      else
        Card.new(suit, value, :number)
      end
    end
  end

  @spec split_by_suits(cards()) :: {cards(), cards(), cards(), cards()}
  def split_by_suits(deck) do
    Enum.reduce(deck, {[], [], [], []}, fn card, {hearts, diamonds, clubs, spades} ->
      case card.suit do
        :hearts -> {[card | hearts], diamonds, clubs, spades}
        :diamonds -> {hearts, [card | diamonds], clubs, spades}
        :clubs -> {hearts, diamonds, [card | clubs], spades}
        :spades -> {hearts, diamonds, clubs, [card | spades]}
      end
    end)
  end

  @spec shuffle(cards()) :: cards()
  def shuffle(deck) do
    Enum.shuffle(deck)
  end
end
