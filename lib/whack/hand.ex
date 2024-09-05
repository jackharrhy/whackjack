defmodule Whack.Hand do
  alias Whack.Card

  @spec calculate_value_of_hand([Card.t()]) :: integer()
  def calculate_value_of_hand(hand) do
    {sum, num_aces} =
      Enum.reduce(hand, {0, 0}, fn card, {total, aces} ->
        {value, new_aces} =
          case card do
            %{value: 1} -> {11, aces + 1}
            %{type: :face} -> {10, aces}
            %{value: v} -> {v, aces}
          end

        {total + value, new_aces}
      end)

    if num_aces > 0 and sum > 21 do
      Enum.reduce_while(1..num_aces, sum, fn _, acc ->
        if acc > 21, do: {:cont, acc - 10}, else: {:halt, acc}
      end)
    else
      sum
    end
  end

  @spec hand_not_busted([Card.t()]) :: :ok | {:error, atom()}
  def hand_not_busted(hand) do
    if hand_not_busted?(hand) do
      :ok
    else
      {:error, :hand_busted}
    end
  end

  @spec hand_not_busted?([Card.t()]) :: boolean()
  def hand_not_busted?(hand) do
    calculate_value_of_hand(hand) <= 21
  end
end
