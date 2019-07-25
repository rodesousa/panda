defmodule Panda.Url do
  use Timex
  @url "https://api.pandascore.co"
  @upcoming "/matches/upcoming"
  @match "/matches/"

  defp token() do
    System.get_env("PANDASCORE_TOKEN")
  end

  defp headers() do
    [Authorization: "Bearer " <> token(), "Content-Type": "application/json"]
  end

  @doc """
  Returns the five first upcoming matches (sorted by begin date)
  """
  @spec upcoming_matches :: Map.t() | no_return
  def upcoming_matches do
    with {:ok, %{body: raw}} =
           HTTPoison.get(@url <> @upcoming, headers(),
             params: %{"sort" => "begin_at", "page[size]" => "5"}
           ) do
      raw
      |> Poison.decode!()
    end
  end

  @doc """
  Returns the whole informations about a match
  """
  @spec get_match(Integer.t()) :: Map.t() | no_return
  def get_match(match_id) do
    with {:ok, %{body: raw}} <- HTTPoison.get(@url <> @match <> "#{match_id}", headers()) do
      raw
      |> Poison.decode!()
    end
  end

  @doc """
  Returns all team matches
  """
  @spec get_matches_of_team(Integer.t()) :: Map.t() | no_return
  def get_matches_of_team(team_id) do
    with {:ok, %{body: raw}} <-
           HTTPoison.get(@url <> "/teams/#{team_id}/matches", headers(),
             params: %{"filter[finished]" => true, "sort" => "begin_at"}
           ) do
      raw
      |> Poison.decode!()
    end
  end

  @doc """
  Returns a tournament
  """
  @spec get_tournament(Integer.t()) :: Map.t() | no_return
  def get_tournament(id) do
    with {:ok, %{body: raw}} <- HTTPoison.get(@url <> "/tournaments/#{id}", headers()) do
      raw
      |> Poison.decode!()
    end
  end
end
