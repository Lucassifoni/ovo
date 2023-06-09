defmodule OvoTestRecursiveBonkedSpecialCase do
  use ExUnit.Case

  test "fibonknacci" do
    code = """
    fibs = !\\a ->
      if greater_or_equals(a, 2) then
        add(fibs(subtract(a, 1)), fibs(subtract(a, 2)))
      else
        1
      end
    end

    fibs(5)

    add(bonk(fibs), bonk(fibs))
    """

    assert {%Ovo.Ast{kind: :integer, nodes: [], value: 11}, _} = Ovo.run(code)
  end

  test "another bonk test" do
    code = """
    add_one = !\\a -> add(a, 1) end
    add_one(1)
    add_one(3)
    add_one(4)
    a = bonk(add_one)
    bonk(add_one)
    add(a, bonk(add_one))
    """

    assert {%Ovo.Ast{kind: :integer, nodes: [], value: 7}, _} = Ovo.run(code)
  end

  test "access test" do
    code = """
    add_one = !\\a -> add(a, 1) end
    fonk = access(`arg0`)
    add_one(fonk)
    """

    assert {%Ovo.Ast{kind: :integer, nodes: [], value: 2}, _} = Ovo.run(code, %{"arg0" => 1})
  end
end
