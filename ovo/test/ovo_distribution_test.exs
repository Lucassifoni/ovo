defmodule OvoDistributionTest do
  use ExUnit.Case, async: false

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

    {:ok, hash1} = Ovo.Runner.register(code1, "foo")
    {:ok, hash2} = Ovo.Runner.register(code2, "bar")

    assert hash2 == "1I9Jp"

    assert {:integer, [], 11} ==
             Ovo.Registry.run_chain([hash2, hash1], [5])

    assert {:integer, [], 15} ==
             Ovo.Registry.run_chain([hash2, hash1], [7])

    assert {:integer, [], 14} ==
             Ovo.Runner.shake(hash2)

    assert {:integer, [], 10} ==
             Ovo.Runner.shake(hash2)

    assert {:integer, [], 16} ==
             Ovo.Runner.run("1I9Jp", [8])
  end

  test "program linking 2" do
    Ovo.Registry.start_link(nil)

    adder = """
    add(arg(0), arg(1))
    """

    add_one = """
    add(arg(0), 1)
    """

    {:ok, ovo_adder} = Ovo.Runner.register(adder, "foo")
    {:ok, ovo_add_one} = Ovo.Runner.register(add_one, "bar")

    add_and_add_one = fn a, b ->
      Ovo.Registry.run_chain([ovo_adder, ovo_add_one], [a, b])
    end

    assert add_and_add_one.(2, 3) == {:integer, [], 6}
    add_and_add_one.(6, 6)
    Ovo.Runner.shake(ovo_add_one)
    assert Ovo.Runner.shake(ovo_add_one) == {:integer, [], 6}
  end

  test "program linking 3" do
    Ovo.Registry.start_link(nil)

    code = """
    bar = arg(0)
    result = multiply(bar, 2)
    result
    """

    {:ok, hash} = Ovo.Runner.register(code, "foo")

    assert hash == "1I9Jp"

    code2 = """
    z = add(arg(0), 5)
    invoke(`1I9Jp`, [z])
    """

    {:ok, dependent_hash} = Ovo.Runner.register(code2, "bar")

    assert Ovo.Runner.run(dependent_hash, [3]) |> Ovo.Converter.ovo_to_elixir() == 16
  end

  test "program linking 4" do
    # Start an Ovo.Registry
    Ovo.Registry.start()

    # Start some Ovo.Runners

    {:ok, ovo_adder} =
      Ovo.Runner.register(
        """
        add(arg(0), arg(1))
        """,
        "bar"
      )

    {:ok, ovo_times2} =
      Ovo.Runner.register(
        """
        multiply(arg(0), 2)
        """,
        "baz"
      )

    {:integer, [], 5} = Ovo.Runner.run(ovo_adder, [2, 3])
    {:integer, [], 10} = Ovo.Runner.run(ovo_times2, [5])
    {:integer, [], 10} = Ovo.Registry.run_chain([ovo_adder, ovo_times2], [2, 3])

    {:ok, dependent_program} =
      Ovo.Runner.register(
        """
          invoke(`9tozX`, [2])
        """,
        "test"
      )

    {:integer, [], 4} = Ovo.Runner.run(dependent_program, [])
    {:integer, [], 4} = Ovo.Runner.shake(dependent_program)
  end
end
