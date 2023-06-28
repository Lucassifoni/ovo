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

    fibs(10)

    add(bonk(fibs), bonk(fibs))
    """
    assert Ovo.run(code) == %Ovo.Ast{kind: :integer, nodes: [], value: 123}
  end
end
