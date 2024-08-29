defmodule Crazy8.Card do
  @suits [:hearts, :diamonds, :clubs, :spades]
  @values [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  @types [:number, :face]

  def suits do
    @suits
  end

  def values do
    @values
  end

  def types do
    @types
  end

  @derive Jason.Encoder
  defstruct [
    :suit,
    :value,
    :type,
    :art
  ]

  def new(suit, value, type) do
    struct!(__MODULE__, %{
      suit: suit,
      value: value,
      type: type,
      art: generate_art(suit, value)
    })
  end

  defp value_to_art(value) do
    case value do
      1 -> "A"
      11 -> "J"
      12 -> "Q"
      13 -> "K"
      _ -> value
    end
  end

  defp generate_art(suit, value) do
    suit_art =
      case suit do
        :clubs -> "♣"
        :diamonds -> "♦"
        :hearts -> "♥"
        :spades -> "♠"
      end

    value_art = value_to_art(value)

    "#{suit_art} #{value_art}"
  end

  def art_url(card) do
    suit = String.capitalize(Atom.to_string(card.suit))
    value = value_to_art(card.value)
    "/images/Cards/card#{suit}#{value}.png"
  end
end

defimpl String.Chars, for: Crazy8.Card do
  def to_string(card) do
    "#{card.art}"
  end
end
