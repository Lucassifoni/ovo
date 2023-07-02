defmodule OvoDistributionTest do
  use ExUnit.Case, async: false
  alias Ovo.Ast

  test "program linking" do
    Ovo.Registry.start_link(nil)

    code1 = """
    foo = arg(0)
    add(foo, 1)
    """

    code2 = """
    bar = arg(0)
    result = multiply(bar, 2)
    result
    """

    {:ok, hash1} = Ovo.Runner.register(code1)
    {:ok, hash2} = Ovo.Runner.register(code2)

    assert hash2 == "juRoIieFP"

    assert %Ast{kind: :integer, value: 11, nodes: []} ==
             Ovo.Registry.run_chain([hash2, hash1], [5])

    assert %Ast{kind: :integer, value: 15, nodes: []} ==
             Ovo.Registry.run_chain([hash2, hash1], [7])

    assert %Ast{kind: :integer, value: 14, nodes: []} ==
             Ovo.Runner.bonk(hash2)

    assert %Ast{kind: :integer, value: 10, nodes: []} ==
             Ovo.Runner.bonk(hash2)

    assert %Ast{kind: :integer, value: 16, nodes: []} ==
             Ovo.Runner.run("juRoIieFP", [8])
  end

  test "program linking 2" do
    Ovo.Registry.start_link(nil)

    adder = """
    add(arg(0), arg(1))
    """

    add_one = """
    add(arg(0), 1)
    """

    {:ok, ovo_adder} = Ovo.Runner.register(adder)
    {:ok, ovo_add_one} = Ovo.Runner.register(add_one)

    add_and_add_one = fn a, b ->
      Ovo.Registry.run_chain([ovo_adder, ovo_add_one], [a, b])
    end

    assert add_and_add_one.(2, 3) == %Ovo.Ast{kind: :integer, nodes: [], value: 6}
    add_and_add_one.(6, 6)
    Ovo.Runner.bonk(ovo_add_one)
    assert Ovo.Runner.bonk(ovo_add_one) == %Ovo.Ast{kind: :integer, nodes: [], value: 6}
  end

  test "program linking 3" do
    Ovo.Registry.start_link(nil)

    code = """
    bar = arg(0)
    result = multiply(bar, 2)
    result
    """

    {:ok, hash} = Ovo.Runner.register(code)

    assert hash == "juRoIieFP"

    code2 = """
    z = add(arg(0), 5)
    invoke(`juRoIieFP`, [z])
    """

    {:ok, dependent_hash} = Ovo.Runner.register(code2)

    assert Ovo.Runner.run(dependent_hash, [3]) |> Ovo.Converter.ovo_to_elixir() == 16
  end
end
