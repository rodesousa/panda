defmodule OddsTests do
  use ExUnit.Case
  import Panda.Url

  @a %{
    1882 => %{
      matches: [
        %{versus: {3248, 5792}, win: true},
        %{versus: {3241, 5792}, win: false},
        %{versus: {5792, 3285}, win: false},
        %{versus: {5792, 5793}, win: false}
      ],
      win: false
    },
    2173 => %{
      matches: [
        %{versus: {5792, 3275}, win: false},
        %{versus: {5792, 125_783}, win: true},
        %{versus: {5792, 125_784}, win: true}
      ],
      win: true
    },
    2174 => %{matches: [%{versus: {5792, 3244}, win: false}], win: false},
    2252 => %{
      matches: [
        %{versus: {125_871, 5792}, win: false},
        %{versus: {3252, 5792}, win: true},
        %{versus: {5792, 125_870}, win: true}
      ],
      win: true
    },
    2255 => %{
      matches: [
        %{versus: {3248, 5792}, win: false},
        %{versus: {125_871, 5792}, win: false},
        %{versus: {5792, 3259}, win: false}
      ],
      win: false
    },
    2472 => %{matches: [%{versus: {5792, 3248}, win: false}], win: true}
  }

  @b %{
    1740 => %{
      matches: [
        %{versus: {3250, 3248}, win: true},
        %{versus: {3249, 3248}, win: false},
        %{versus: {3248, 3219}, win: false},
        %{versus: {3248, 3212}, win: false}
      ],
      win: false
    },
    1744 => %{
      matches: [
        %{versus: {3251, 3248}, win: false},
        %{versus: {3219, 3248}, win: true},
        %{versus: {3241, 3248}, win: false},
        %{versus: {3248, 3249}, win: false}
      ],
      win: false
    },
    1796 => %{
      matches: [
        %{versus: {3211, 3248}, win: false},
        %{versus: {3258, 3248}, win: true},
        %{versus: {3248, 3209}, win: false}
      ],
      win: false
    },
    1882 => %{
      matches: [
        %{versus: {3248, 5792}, win: false},
        %{versus: {3248, 5793}, win: true},
        %{versus: {3248, 3285}, win: false}
      ],
      win: false
    }
  }

  test "returns all matches for a year" do
    with response <-
           get_matches_of_team(648) do
      filtered_response =
        response
        |> Panda.Odds.filter_by_date()

      assert Enum.count(response) > Enum.count(filtered_response)
    end
  end

  test "returns tournaments matches by tournament id" do
    with matches <-
           get_matches_of_team(648) do
      m1 =
        matches
        |> Enum.filter(fn %{"tournament_id" => id} -> id == 410 or id == 750 end)
        |> Panda.Odds.get_matches_by_tournament(648)

      assert Enum.count(m1) == 2

      m2 =
        matches
        |> Enum.uniq_by(fn %{"tournament_id" => id} -> id end)
        |> Enum.count()

      m3 =
        matches
        |> Panda.Odds.get_matches_by_tournament(648)
        |> Enum.count()

      assert m2 == m3
    end
  end

  test "checks the confrontation ratio between 2 teams" do
    c1 = Panda.Odds.win_teams_confrontation({5792, @a}, {3248, %{}})

    assert c1 == {7, 28}
  end

  test "checks the confrontation ratio with 0 match between teams" do
    c1 = Panda.Odds.win_teams_confrontation({5793, @a}, {3248, %{}})
    assert c1 == {17.5, 17.5}
    c2 = Panda.Odds.win_teams_confrontation({5793, %{}}, {3248, %{}})
    assert c2 == {17.5, 17.5}
  end

  test "compares ratio of won tournament" do
    ratio =
      {"", @a}
      |> Panda.Odds.ratio_tournament_won({"", @b})

    assert ratio == {35, 0}
  end

  test "checks ratio of won tournament with 0 tournament" do
    ratio_1 =
      {"", %{}}
      |> Panda.Odds.ratio_tournament_won({"", @b})

    assert ratio_1 == {17.5, 17.5}

    ratio_2 =
      {"", %{}}
      |> Panda.Odds.ratio_tournament_won({"", %{}})

    assert ratio_2 == {17.5, 17.5}
  end

  test "compares ratio of won match" do
    ratio =
      {"", @a}
      |> Panda.Odds.ratio_match_won({"", @b})

    assert ratio == {8.333333333333334, 6.666666666666666}
  end

  test "compares ratio of won match with 0 match" do
    ratio_1 =
      {"", %{}}
      |> Panda.Odds.ratio_match_won({"", @b})

    assert ratio_1 == {0, 15}

    ratio_2 =
      {"", %{}}
      |> Panda.Odds.ratio_match_won({"", %{}})

    assert ratio_2 == {7.5, 7.5}
  end

  test "checks ratio of matches between 2 teams with 0 match" do
    c1 = Panda.Odds.ratio_matches({1, @a}, {1, %{}})
    c2 = Panda.Odds.ratio_matches({1, %{}}, {1, @a})
    c3 = Panda.Odds.ratio_matches({1, %{}}, {1, %{}})
    assert c1 == {10, 0}
    assert c2 == {0, 10}
    assert c3 == {5, 5}
  end

  test "transforms ratio into point" do
    assert Panda.Odds.transform_ratio_to_point([0.5, 0.5], 20) == {10, 10}
  end

  test "transforms ratio into point with some ratio eq 0" do
    assert Panda.Odds.transform_ratio_to_point([1, 0], 20) == {20, 00}
    assert Panda.Odds.transform_ratio_to_point([0, 1], 20) == {0, 20}
    assert Panda.Odds.transform_ratio_to_point([0.0, 0.0], 20) == {10, 10}
  end
end
