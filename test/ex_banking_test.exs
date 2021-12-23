defmodule ExBankingTest do
  use ExUnit.Case

  describe "create_user/1" do
    test "creates user once" do
      assert ExBanking.create_user("foo") == :ok
      assert ExBanking.create_user("foo") == {:error, :user_already_exists}
    end

    test "validates arguments" do
      assert ExBanking.create_user(123) == {:error, :wrong_arguments}
    end
  end

  describe "get_balance/2" do
    test "requires existing user" do
      assert ExBanking.get_balance("uknown", "SAR") == {:error, :user_does_not_exist}
    end

    test "validates arguments" do
      assert ExBanking.get_balance(123, "USD") == {:error, :wrong_arguments}
      assert ExBanking.get_balance("user", 1) == {:error, :wrong_arguments}
      assert ExBanking.get_balance(2, 1) == {:error, :wrong_arguments}
    end

    test "returns balance" do
      ExBanking.create_user("test1")
      assert ExBanking.get_balance("test1", "USD") == {:ok, 0}
    end
  end

  describe "deposit/3" do
    test "validates arguments" do
      ExBanking.create_user("test2")
      assert ExBanking.deposit(1, 10, "SAR") == {:error, :wrong_arguments}
      assert ExBanking.deposit("test2", -10, "SAR") == {:error, :wrong_arguments}
      assert ExBanking.deposit("test2", 10, 1) == {:error, :wrong_arguments}
    end

    test "requires existing user" do
      assert ExBanking.deposit("uknown", 10, "SAR") == {:error, :user_does_not_exist}
    end

    test "deposits positive amount" do
      ExBanking.create_user("test3")
      assert ExBanking.deposit("test3", 10.231, "SAR") == {:ok, 10.23}
      assert ExBanking.deposit("test3", 5, "SAR") == {:ok, 15.23}
    end

    test "works with multiple currenies" do
      ExBanking.create_user("test4")
      assert ExBanking.deposit("test4", 1.1, "SAR") == {:ok, 1.1}
      assert ExBanking.deposit("test4", 2.2, "USD") == {:ok, 2.2}
    end
  end

  describe "withdraw/3" do
    test "validates arguments" do
      ExBanking.create_user("test5")
      assert ExBanking.withdraw(1, 10, "SAR") == {:error, :wrong_arguments}
      assert ExBanking.withdraw("test5", "foo", "SAR") == {:error, :wrong_arguments}
      assert ExBanking.withdraw("test5", 10, 1) == {:error, :wrong_arguments}
    end

    test "requires existing user" do
      assert ExBanking.withdraw("uknown", 10, "SAR") == {:error, :user_does_not_exist}
    end

    test "withdraws money" do
      ExBanking.create_user("test6")
      ExBanking.deposit("test6", 10, "SAR")
      assert ExBanking.withdraw("test6", 5, "SAR") == {:ok, 5.0}
      assert ExBanking.withdraw("test6", 5, "SAR") == {:ok, 0.0}
      assert ExBanking.withdraw("test6", 5, "SAR") == {:error, :not_enough_money}
    end
  end

  describe "send/4" do
    test "requires sender" do
      assert ExBanking.send("from", "to", 3, "SAR") == {:error, :sender_does_not_exist}
    end

    test "requires receiver" do
      ExBanking.create_user("from")
      assert ExBanking.send("from", "to", 3, "SAR") == {:error, :receiver_does_not_exist}
    end

    test "controls balance" do
      ExBanking.create_user("from1")
      ExBanking.create_user("to1")
      assert ExBanking.send("from1", "to1", 3, "SAR") == {:error, :not_enough_money}
    end

    test "transfers funds" do
      ExBanking.create_user("from2")
      ExBanking.create_user("to2")
      ExBanking.deposit("from2", 10, "SAR")
      assert ExBanking.send("from2", "to2", 3, "SAR") == {:ok, 7.0, 3.0}
      assert ExBanking.get_balance("from2", "SAR") == {:ok, 7.0}
      assert ExBanking.get_balance("to2", "SAR") == {:ok, 3.0}
    end
  end
end
