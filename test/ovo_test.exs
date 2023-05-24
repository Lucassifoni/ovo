defmodule OvoTest do
  use ExUnit.Case
  doctest Ovo

  test "Tokenizes input, removing whitespace." do
    for {program, tokens} <- [
          {"foo = 5", [{:nonstring, "foo"}, {:equals, nil}, {:number, "5"}]}
        ] do
      assert Ovo.tokenize(program) == tokens
    end
  end

  test "Tokenizes input, correctly handling string beginning and end" do
    for {program, tokens} <- [
          {"foo = `heya`", [{:nonstring, "foo"}, {:equals, nil}, {:string, "heya"}]}
        ] do
      assert Ovo.tokenize(program) == tokens
    end
  end

  test "Tokenizes input, correctly handling backtick" do
    for {program, tokens} <- [
          {"foo = `heya`\nbar = `baz\\`baz`",
           [
             {:nonstring, "foo"},
             {:equals, nil},
             {:string, "heya"},
             {:nonstring, "bar"},
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
              {:nonstring, "foo"},
              {:equals, nil},
              {:number, "5"},
              {:nonstring, "bar"},
              {:equals, nil},
              {:string, "stringy` value"},
              {:nonstring, "baz"},
              {:open_paren, nil},
              {:nonstring, "a"},
              {:comma, nil},
              {:nonstring, "b"},
              {:comma, nil},
              {:nonstring, "c"},
              {:comma, nil},
              {:nonstring, "d"},
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
      {:nonstring, "bar"},
      {:arrow, nil},
      {:nonstring, "baz"},
      {:if, nil},
      {:nonstring, "bar"},
      {:then, nil},
      {:number, "5"},
      {:else, nil},
      {:end, nil}
    ]

    assert Ovo.tokenize(program) == tokens
  end

  test "Tokenizes commas, lists, parents, backslashes" do
    program = """
    \\a, b -> ([a, b, c])
    """

    tokens = [
      {:backslash, nil},
      {:nonstring, "a"},
      {:comma, nil},
      {:nonstring, "b"},
      {:arrow, nil},
      {:open_paren, nil},
      {:open_bracket, nil},
      {:nonstring, "a"},
      {:comma, nil},
      {:nonstring, "b"},
      {:comma, nil},
      {:nonstring, "c"},
      {:close_bracket, nil},
      {:close_paren, nil}
    ]

    assert Ovo.tokenize(program) == tokens
  end

  def parse(input), do: input |> Ovo.Tokenizer.tokenize() |> Ovo.Parser.parse()

  test "Parses a simple expression" do
    assert parse("foo = bar\nbaz = 5.25") == %Ovo.Ast{
             kind: :root,
             nodes: [
               [
                 %Ovo.Ast{
                   kind: :assignment,
                   nodes: [
                     %Ovo.Ast{kind: :symbol, nodes: nil, value: "foo"},
                     %Ovo.Ast{kind: :nonstring, nodes: nil, value: "bar"}
                   ],
                   value: nil
                 }
               ],
               [
                 %Ovo.Ast{
                   kind: :assignment,
                   nodes: [
                     %Ovo.Ast{kind: :symbol, nodes: nil, value: "baz"},
                     %Ovo.Ast{kind: :number, nodes: nil, value: "5.25"}
                   ],
                   value: nil
                 }
               ]
             ],
             value: nil
           }
  end
end
