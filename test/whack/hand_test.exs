defmodule Whack.HandTest do
  use ExUnit.Case
  alias Whack.{Hand, Card}

  describe "calculate_value_of_hand/1" do
    test "calculates the value of a hand with number cards" do
      hand = [
        Card.new(:hearts, 5, :number),
        Card.new(:clubs, 7, :number)
      ]

      assert Hand.calculate_value_of_hand(hand) == 12
    end

    test "calculates the value of a hand with face cards" do
      hand = [
        Card.new(:diamonds, 10, :number),
        Card.new(:spades, 12, :face),
        Card.new(:hearts, 13, :face)
      ]

      assert Hand.calculate_value_of_hand(hand) == 30
    end

    test "calculates the value of a hand with a queen, 3, and 2" do
      hand = [
        Card.new(:spades, 12, :face),
        Card.new(:spaces, 3, :number),
        Card.new(:spades, 2, :number)
      ]

      assert Hand.calculate_value_of_hand(hand) == 15
    end

    test "calculates the value of a hand with an ace as 11" do
      hand = [
        Card.new(:clubs, 1, :number),
        Card.new(:hearts, 7, :number)
      ]

      assert Hand.calculate_value_of_hand(hand) == 18
    end

    test "calculates the value of a hand with an ace as 1 to avoid busting" do
      hand = [
        Card.new(:spades, 1, :number),
        Card.new(:diamonds, 10, :number),
        Card.new(:hearts, 5, :number)
      ]

      assert Hand.calculate_value_of_hand(hand) == 16
    end

    test "calculates the value of a hand with multiple aces" do
      hand = [
        Card.new(:hearts, 1, :number),
        Card.new(:spades, 1, :number),
        Card.new(:diamonds, 1, :number),
        Card.new(:clubs, 8, :number)
      ]

      assert Hand.calculate_value_of_hand(hand) == 21
    end

    test "calculates the value of an empty hand" do
      assert Hand.calculate_value_of_hand([]) == 0
    end
  end
end
