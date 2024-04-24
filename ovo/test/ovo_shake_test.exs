defmodule OvoTestRecursiveShakenSpecialCase do
  use ExUnit.Case

  test "fishakenacci" do
    code = """
    fibs = !\\a ->
      if a >= 2 then
        add(fibs(subtract(a, 1)), fibs(subtract(a, 2)))
      else
        1
      end
    end

    fibs(5)
    """

    assert {{:integer, [], 8}, _} = Ovo.run(code)
  end

  test "another shake test" do
    code = """
    add_one = !\\a -> add(a, 1) end
    add_one(1)
    add_one(3)
    add_one(4)
    a = shake(add_one)
    shake(add_one)
    add(a, shake(add_one))
    """

    assert {{:integer, [], 7}, _} = Ovo.run(code)
  end

  test "access test" do
    code = """
    add_one = !\\a -> add(a, 1) end
    fonk = access(`arg0`)
    add_one(fonk)
    """

    assert {{:integer, [], 2}, _} = Ovo.run(code, %{"arg0" => 1})
  end
end
