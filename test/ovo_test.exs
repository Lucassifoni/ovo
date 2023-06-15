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
            foo = 500
            bar = `stringy\\` value`
            baz(a,b,c,d)
            """,
            [
              {:symbol, "foo"},
              {:equals, nil},
              {:number, "500"},
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
    \\a, b -> ( [ a , b, add(b, 5) ] )
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

  test "Complex expression" do
    assert Ovo.tokenize("if foo then 5 else [4, 5, 6] end") == [
             if: nil,
             symbol: "foo",
             then: nil,
             number: "5",
             else: nil,
             open_bracket: nil,
             number: "4",
             comma: nil,
             number: "5",
             comma: nil,
             number: "6",
             close_bracket: nil,
             end: nil
           ]
  end

  def parse(input), do: input |> Ovo.tokenize() |> Ovo.parse()

  test "Fully parses complex expressions" do
    {:ok, _, []} = parse("if (foo) then ([5]) else ([4, [5, 4, []], [[[]]], 6]) (baz) end")
  end

  test "Parses an argless function call" do
    {:ok,
     %Ovo.Ast{
       kind: :root,
       value: nil,
       nodes: [%Ovo.Ast{kind: :expr, value: %Ovo.Ast{kind: :call}}]
     }, []} = parse("foo()")
  end

  test "Parses a single-arg function call" do
    {:ok,
     %Ovo.Ast{
       kind: :root,
       value: nil,
       nodes: [
         %Ovo.Ast{
           kind: :expr,
           value: %Ovo.Ast{
             kind: :call,
             nodes: [%Ovo.Ast{kind: :expr, value: %Ovo.Ast{kind: :symbol}}]
           }
         }
       ]
     }, []} = parse("foo(bar)")
  end

  test "Parses a multi-arg function call" do
    {:ok,
     %Ovo.Ast{
       kind: :root,
       value: nil,
       nodes: [
         %Ovo.Ast{
           kind: :expr,
           value: %Ovo.Ast{
             kind: :call,
             nodes: [
               %Ovo.Ast{kind: :expr, value: %Ovo.Ast{kind: :symbol}},
               %Ovo.Ast{kind: :expr, value: %Ovo.Ast{kind: :symbol}}
             ]
           }
         }
       ]
     }, []} = parse("foo(bar, baz)")
  end

  def parse_print_parse(input) do
    {:ok, parsed, _} = input |> parse()
    printed = parsed |> Ovo.Printer.print()
    {:ok, reparsed, _} = printed |> parse()
    assert parsed == reparsed
  end

  test "Print loop" do
    parse_print_parse("foo(bar)")
  end

  test "Complex print loop" do
    code = """
    if (foo) then
      ([5])
    else
      ([4, [5, 4, []], [[[]]], 6])
      (baz)
    end
    """

    parse_print_parse(code)
  end

  test "0-arity Lambda print loop" do
    code = """
    \\ ->
      add(a, b)
    end
    """

    parse_print_parse(code)
  end

  test "1-arity Lambda print loop" do
    code = """
    \\a ->
      add(a, b)
    end
    """

    parse_print_parse(code)
  end

  test "n-arity Lambda print loop" do
    code = """
    \\a, b ->
      add(a, b)
    end
    """

    parse_print_parse(code)
  end

  test "assignments" do
    for snippet <- ["foo = 5", "foo = bar", "foo = add(5, bar)"] do
      parse_print_parse(snippet)
    end
  end

  test "full program" do
    program = """
    bar = 6
    baz = T
    foobur = `saluTations`
    age = add(access(data, `age`), bar)

    say_hi = \\name, age ->
      join([name, `has the age`, to_string(age)], ``)
    end

    say_hi(access(data, `name`), age)

    fibs = \\a ->
      if greater_or_equals(a, 2) then
          add(fibs(subtract(a, 1)), fibs(subtract(a, 2)))
      else
          1
      end
    end

    fibs(10)
    """

    parse_print_parse(program)
  end

  test "basic evaluation" do
    program = "addone = \\a -> add(1, a) end addone(2)"
    assert Ovo.run(program) == %Ovo.Ast{kind: :integer, nodes: [], value: 3}
  end

  test "basic evaluation 2" do
    program = fn num ->
      """
      sometimes_add_things = \\a -> if equals(a, 0) then
          add(add(1, a), 2)
        else
          2
        end
      end

      sometimes_add_things(#{num})
      """
    end

    assert Ovo.run(program.(2)) == %Ovo.Ast{kind: :integer, nodes: [], value: 2}
    assert Ovo.run(program.(0)) == %Ovo.Ast{kind: :integer, nodes: [], value: 3}
  end
end
