defmodule UrlTests do
  use ExUnit.Case
  import Panda.Url

  test "check string and integer for get_match" do
    a = get_match(545_739)
    b = get_match("545739")

    assert a === b
  end
end
