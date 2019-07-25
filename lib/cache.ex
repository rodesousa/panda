defmodule Panda.Cache do
  @cache_key :pandascore

  def write(key, value) do
    :ets.insert(@cache_key, {key, value})
  end

  ## Dirty ...
  def init do
    try do
      :ets.new(@cache_key, [:set, :public, :named_table])
    rescue
      _ ->
        nil
    end
  end

  def get(key) do
    :ets.lookup(@cache_key, key)
  end
end
