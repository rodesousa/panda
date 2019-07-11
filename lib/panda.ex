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
end
