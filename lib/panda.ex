defmodule Panda do
  @doc """
  Returns the five first upcoming matches (sorted by begin date)
  """
  @spec upcoming_matches :: map | no_return
  def upcoming_matches do
    Panda.Url.upcoming_matches()
    |> upcoming_matches_response
  end

  @spec upcoming_matches_response(Map.t(), List.t()) :: Map.t()
  defp upcoming_matches_response(raw, response \\ []) do
    match_light = fn match ->
      %{
        "begin_at" => Map.get(match, "begin_at"),
        "id" => Map.get(match, "id"),
        "name" => Map.get(match, "name")
      }
    end

    case raw do
      [head | tail] -> upcoming_matches_response(tail, response ++ [match_light.(head)])
      _ -> response
    end
  end

  @doc """
  Returns odds between two teams for a match
  """
  @spec odds_for_match(Integer.t() | String.t()) :: Map.t()
  def odds_for_match(match_id) do
    with %{"opponents" => opponents} <- Panda.Url.get_match(match_id) do
      if Enum.count(opponents) == 2 do
        Panda.Cache.init()

        case Panda.Cache.get(match_id) do
          [] ->
            tasks_for_odds(match_id, opponents)

          [{_, odds}] ->
            odds
        end
      else
        "There is/are #{Enum.count(opponents)} opponent(s) in this match"
      end
    end
  end

  defp tasks_for_odds(match_id, opponents) do
    [a, b] =
      opponents
      |> Panda.Odds.generate()

    result =
      [
        Panda.Odds.win_teams_confrontation(a, b),
        Panda.Odds.ratio_tournaments(a, b),
        Panda.Odds.ratio_matches(a, b),
        Panda.Odds.ratio_match_won(a, b),
        Panda.Odds.ratio_tournament_won(a, b)
      ]
      |> Enum.reduce({0, 0}, fn {x, y}, {i, j} -> {x + i, y + j} end)
      |> (fn {x, y} ->
            %{
              Enum.at(opponents, 0)["opponent"]["slug"] => x,
              Enum.at(opponents, 1)["opponent"]["slug"] => y
            }
          end).()

    Panda.Cache.write(match_id, result)
    result
  end
end
