defmodule ExBanking do
  @moduledoc """
  Simple banking.
  """

  use Application

  @impl true
  def start(_type, _args) do
    {:ok, _} = Registry.start_link(keys: :unique, name: Registry.Users)
  end

  @doc """
  Function creates new user in the system
  New user has zero balance of any currency
  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    with nil <- lookup_user(user),
         {:ok, _} <- Wallet.start_link(name: {:via, Registry, {Registry.Users, user}}) do
      :ok
    else
      _ -> {:error, :user_already_exists}
    end
  end

  def create_user(_) do
    {:error, :wrong_arguments}
  end

  # Increases user’s balance in given currency by amount value
  # Returns new_balance of the user in given format
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) and amount >= 0 do
    case lookup_user(user) do
      nil -> {:error, :user_does_not_exist}
      pid -> Wallet.update(pid, currency, amount)
    end
  end

  def deposit(_, _, _) do
    {:error, :wrong_arguments}
  end

  # Decreases user’s balance in given currency by amount value
  # Returns new_balance of the user in given format
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) and amount >= 0 do
    case lookup_user(user) do
      nil -> {:error, :user_does_not_exist}
      pid -> Wallet.update(pid, currency, -amount)
    end
  end

  def withdraw(_, _, _) do
    {:error, :wrong_arguments}
  end

  # Returns balance of the user in given format
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    case lookup_user(user) do
      nil -> {:error, :user_does_not_exist}
      pid -> Wallet.get(pid, currency)
    end
  end

  def get_balance(_, _) do
    {:error, :wrong_arguments}
  end

  # Decreases from_user’s balance in given currency by amount value
  # Increases to_user’s balance in given currency by amount value
  # Returns balance of from_user and to_user in given format
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_binary(currency) and
             is_number(amount) and amount >= 0 do
    case [lookup_user(from_user), lookup_user(to_user)] do
      [nil, _] -> {:error, :sender_does_not_exist}
      [_, nil] -> {:error, :receiver_does_not_exist}
      [from_pid, to_pid] -> Wallet.transfer(from_pid, to_pid, currency, amount)
    end
  end

  def send(_, _, _, _) do
    {:error, :wrong_arguments}
  end

  def lookup_user(user) do
    case Registry.lookup(Registry.Users, user) do
      [{pid, _}] -> pid
      _ -> nil
    end
  end
end
