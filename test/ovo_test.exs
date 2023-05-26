defmodule OvoTest do
  use ExUnit.Case
  doctest Ovo
  doctest Ovo.Tokenizer
  doctest Ovo.Parser
  doctest Ovo.Combinators

  test "Tokenizes input, removing whitespace." do
    for {program, tokens} <- [
          {"foo = 5", [{:symbol, "foo"}, {:equals, nil}, {:number, "5"}]}
        ] do
      assert Ovo.tokenize(program) == tokens
    end
  end

  test "Tokenizes input, correctly handling string beginning and end" do
    for {program, tokens} <- [
          {"foo = `heya`", [{:symbol, "foo"}, {:equals, nil}, {:string, "heya"}]}
        ] do
      assert Ovo.tokenize(program) == tokens
    end
  end

  test "Tokenizes input, correctly handling backtick" do
    for {program, tokens} <- [
          {"foo = `heya`\nbar = `baz\\`baz`",
           [
             {:symbol, "foo"},
             {:equals, nil},
             {:string, "heya"},
             {:symbol, "bar"},
             {:equals, nil},
             {:string, "baz`baz"}
           ]}
        ] do
      assert Ovo.tokenize(program) == tokens
    end
  end

  test "Tokenizes more complex input" do
    for {program, tokens} <- [
          {
            """
            foo = 5
            bar = `stringy\\` value`
            baz(a,b,c,d)
            """,
            [
              {:symbol, "foo"},
              {:equals, nil},
              {:number, "5"},
              {:symbol, "bar"},
              {:equals, nil},
              {:string, "stringy` value"},
              {:symbol, "baz"},
              {:open_paren, nil},
              {:symbol, "a"},
              {:comma, nil},
              {:symbol, "b"},
              {:comma, nil},
              {:symbol, "c"},
              {:comma, nil},
              {:symbol, "d"},
              {:close_paren, nil}
            ]
          }
        ] do
      assert Ovo.tokenize(program) == tokens
    end
  end

  test "Tokenizes arrows and if/then/else/end" do
    program = """
    bar -> baz
    if bar then 5 else end
    """

    tokens = [
      {:symbol, "bar"},
      {:arrow, nil},
      {:symbol, "baz"},
      {:if, nil},
      {:symbol, "bar"},
      {:then, nil},
      {:number, "5"},
      {:else, nil},
      {:end, nil}
    ]

    assert Ovo.tokenize(program) == tokens
  end

  test "Tokenizes commas, lists, parents, backslashes" do
    program = """
    \\a, b -> ([a, b, add(b, 5)])
    """

    tokens = [
      {:backslash, nil},
      {:symbol, "a"},
      {:comma, nil},
      {:symbol, "b"},
      {:arrow, nil},
      {:open_paren, nil},
      {:open_bracket, nil},
      {:symbol, "a"},
      {:comma, nil},
      {:symbol, "b"},
      {:comma, nil},
      {:symbol, "add"},
      {:open_paren, nil},
      {:symbol, "b"},
      {:comma, nil},
      {:number, "5"},
      {:close_paren, nil},
      {:close_bracket, nil},
      {:close_paren, nil}
    ]

    assert Ovo.tokenize(program) == tokens
  end

  def parse(input), do: input |> Ovo.tokenize()
end
