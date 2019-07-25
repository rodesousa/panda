defmodule Panda.Odds do
  import Panda.Url

  @doc """
  Generates a list of matches (by tournament) with the team id
  """
  @spec generate(List.t()) :: List.t()
  def generate(opponents) do
    opponents
    # |> Enum.map(fn %{"opponent" => opp} ->
    |> Task.async_stream(fn %{"opponent" => opp} ->
      value =
        case Panda.Cache.get(opp["id"]) do
          [] ->
            tournaments =
              opp["id"]
              |> get_matches_of_team
              |> filter_by_date
              |> get_matches_by_tournament(opp["id"])

            Panda.Cache.write(opp["id"], tournaments)
            tournaments

          [{_, value}] ->
            value
        end

      {opp["id"], value}
    end)
    |> Enum.map(fn {_, element} -> element end)
  end

  @doc """
  Filter by date
  By default `format` :year and diff 0
  `returns all the matches for a year`
  """
  @spec filter_by_date(Map.t(), Atom.t(), Integer.t()) :: Map.t() | no_return
  def filter_by_date(matches, format \\ :year, diff \\ 0) do
    matches
    |> Enum.filter(fn match ->
      case Map.get(match, "end_at") do
        nil ->
          false

        end_at ->
          with {:ok, date, _} <- DateTime.from_iso8601(end_at) do
            Timex.diff(date, DateTime.utc_now(), format) == diff
          else
            _ -> false
          end
      end
    end)
  end

  @doc """
  For each match returns %{tournament_id: [matches]}
  """
  @spec get_matches_by_tournament(List.t(), Integer.t(), Map.t()) :: Map.t()
  def get_matches_by_tournament([head | tail], team_id, response \\ %{}) do
    id =
      head
      |> Map.get("tournament_id")

    response
    |> Map.get(id)
    |> case do
      nil ->
        with %{"winner_id" => win_id} <- get_tournament(id),
             tournament <- %{matches: [tournament_info(head, team_id)], win: win_id == team_id} do
          tail
          |> get_matches_by_tournament(team_id, Map.put(response, id, tournament))
        end

      _ ->
        with matches <- response[id][:matches] ++ [tournament_info(head, team_id)],
             tournament <- %{response[id] | matches: matches} do
          tail
          |> get_matches_by_tournament(team_id, %{response | id => tournament})
        end
    end
  end

  @spec get_matches_by_tournament([], any, Map.t()) :: Map.t()
  def get_matches_by_tournament([], _, response), do: response

  @spec tournament_info(Map.t(), Integer.t()) :: Map.t()
  defp tournament_info(%{"opponents" => [a, b], "winner_id" => win_id}, team_id),
    do: %{versus: {a["opponent"]["id"], b["opponent"]["id"]}, win: win_id == team_id}

  @doc """
  Calculates the win ratio between direct confrontations between 2 teams
  """
  @spec win_teams_confrontation(Tuple.t(), Tuple.t()) :: Tuple.t()
  def win_teams_confrontation({a_id, team_a_tournaments}, {b_id, _}) do
    team_a_tournaments
    |> flat_map_matches()
    |> score_between_teams(a_id, b_id)
    |> (fn {a_score, b_score} ->
          with total <- a_score + b_score,
               a_ratio <- safe_division({a_score, total}),
               b_ratio <- safe_division({b_score, total}) do
            transform_ratio_to_point([a_ratio, b_ratio], 35)
          end
        end).()
  end

  @spec score_between_teams(List.t(), Integer.t(), Integer.t()) :: Tuple.t()
  defp score_between_teams(array, a_id, b_id) do
    array
    |> Enum.reduce({0, 0}, fn %{versus: {x, y}, win: bool}, {a, b} ->
      cond do
        {x, y} == {a_id, b_id} or {x, y} == {b_id, a_id} ->
          if(bool == true, do: {a + 1, b}, else: {a, b + 1})

        true ->
          {a, b}
      end
    end)
  end

  @doc """
  Compares number of tournaments played between 2 teams
  """
  @spec ratio_tournaments(Tuple.t(), Tuple.t()) :: Tuple.t()
  def ratio_tournaments({_, team_a_tournaments}, {_, team_b_tournaments}) do
    [team_a_tournaments, team_b_tournaments]
    |> Enum.map(&Enum.count(&1))
    |> transform_ratio_to_point(5)
  end

  @doc """
  Compares number of matches played between 2 teams
  """
  @spec ratio_matches(Tuple.t(), Tuple.t()) :: Tuple.t()
  def ratio_matches({_, team_a_tournaments}, {_, team_b_tournaments}) do
    [team_a_tournaments, team_b_tournaments]
    |> Enum.map(fn tournaments ->
      tournaments
      |> flat_map_matches()
      |> Enum.count()
    end)
    |> transform_ratio_to_point(10)
  end

  @doc """
  Ratio number of matches won / number of matches played between 2 teams
  """
  @spec ratio_match_won(Tuple.t(), Tuple.t()) :: Tuple.t()
  def ratio_match_won({_, team_a_tournaments}, {_, team_b_tournaments}) do
    ratio = fn map ->
      map
      |> flat_map_matches()
      |> Enum.reduce({0, 0}, fn %{win: bool}, {wins, matches} ->
        if bool == true, do: {wins + 1, matches + 1}, else: {wins, matches + 1}
      end)
      |> safe_division
    end

    [ratio.(team_a_tournaments), ratio.(team_b_tournaments)]
    |> transform_ratio_to_point(15)
  end

  @doc """
  Ratio number of tournaments won / number of tournaments played between 2 teams
  """
  @spec ratio_tournament_won(Tuple.t(), Tuple.t()) :: Tuple.t()
  def ratio_tournament_won({_, team_a_tournaments}, {_, team_b_tournaments}) do
    ratio = fn tournaments ->
      tournaments
      |> Enum.reduce({0, 0}, fn {_, %{win: bool}}, {wins, matches} ->
        if bool == true, do: {wins + 1, matches + 1}, else: {wins, matches + 1}
      end)
      |> safe_division
    end

    [ratio.(team_a_tournaments), ratio.(team_b_tournaments)]
    |> transform_ratio_to_point(35)
  end

  @doc """
  Compares ratios and splits/converts them into `total_points` points
  """
  @spec transform_ratio_to_point(List.t(), Integer.t()) :: Tuple.t()
  def transform_ratio_to_point([team_a_ratio, team_b_ratio], total_points) do
    team_a_ratio
    |> compare_ratios(team_b_ratio)
    |> case do
      0.0 ->
        {0, total_points}

      1.0 ->
        {total_points, 0}

      ratio ->
        {ratio * total_points, (1 - ratio) * total_points}
    end
  end

  @spec compare_ratios(Float.t(), Float.t()) :: Float.t()
  defp compare_ratios(a, b) do
    # Implementation of https://sabr.org/research/probabilities-victory-head-head-team-matchups 
    case {a, b} do
      {0.0, 0.0} -> 0.5
      {0, 0} -> 0.5
      # against demo effect :D
      _ -> (a - a * b) / (a - a * b + b - b * a)
    end
  end

  @spec safe_division(Tuple.t()) :: Float.t()
  defp safe_division({dividend, total}) do
    cond do
      dividend == 0 or total == 0 -> 0.0
      true -> dividend / total
    end
  end

  @spec flat_map_matches(Map.t()) :: Map.t()
  defp flat_map_matches(array) do
    array
    |> Enum.flat_map(fn {_, %{matches: y}} -> y end)
  end
end
