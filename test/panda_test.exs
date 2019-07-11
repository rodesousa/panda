defmodule PandaTests do
  use ExUnit.Case

  test "transform upcoming_matches response into simple map " do
    response = Panda.upcoming_matches()
    assert Enum.count(response) == 5
    assert Enum.at(response, 0)["begin_at"] != nil
    assert Enum.at(response, 0)["id"] != nil
    assert Enum.at(response, 0)["name"] != nil
    assert Enum.count(Enum.at(response, 0)) == 3
  end
end
