defmodule Wallet do
  use GenServer

  @max_requests 10
  @precision 2

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  def get(pid, currency) do
    GenServer.call(pid, {:get, currency})
  end

  def update(pid, currency, amount) do
    GenServer.call(pid, {:update, currency, amount})
  end

  def transfer(from_pid, to_pid, currency, amount) do
    GenServer.call(from_pid, {:transfer, to_pid, currency, amount})
  end

  @impl true
  def handle_call({:get, currency}, _from, wallet) do
    case throttle() do
      :throttled ->
        {:reply, {:error, :too_many_requests_to_user}, wallet}

      :ok ->
        balance = Map.get(wallet, currency, 0.0)
        {:reply, {:ok, format_amount(balance)}, wallet}
    end
  end

  def handle_call({:update, currency, amount}, _from, wallet) do
    case throttle() do
      :throttled -> {:reply, {:error, :too_many_requests_to_user}, wallet}
      :ok -> update_balance(wallet, currency, amount)
    end
  end

  def handle_call({:transfer, to_pid, currency, amount}, _from, wallet) do
    with :ok <- throttle(),
         {:reply, {:ok, sender_balance}, updated_wallet} <-
           update_balance(wallet, currency, -amount),
         {:ok, receiver_balance} <- Wallet.update(to_pid, currency, amount) do
      {:reply, {:ok, sender_balance, receiver_balance}, updated_wallet}
    else
      :throttled ->
        {:reply, {:error, :too_many_requests_to_sender}, wallet}

      {:error, :too_many_requests_to_user} ->
        {:reply, {:error, :too_many_requests_to_receiver}, wallet}

      response ->
        response
    end
  end

  defp update_balance(wallet, currency, amount) do
    {balance, updated_wallet} =
      Map.get_and_update(wallet, currency, fn value ->
        new_amount = (value || 0.0) + amount
        {new_amount, new_amount}
      end)

    if balance < 0.0 do
      {:reply, {:error, :not_enough_money}, wallet}
    else
      {:reply, {:ok, format_amount(balance)}, updated_wallet}
    end
  end

  defp throttle() do
    {:message_queue_len, size} = Process.info(self(), :message_queue_len)

    if size > @max_requests do
      :throttled
    else
      :ok
    end
  end

  defp format_amount(value) do
    Float.round(value, @precision)
  end
end
