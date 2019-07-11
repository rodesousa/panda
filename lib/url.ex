defmodule Panda.Url do
  @url "https://api.pandascore.co"
  @upcoming "/matches/upcoming"

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
end
