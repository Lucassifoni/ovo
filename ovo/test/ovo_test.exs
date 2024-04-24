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
     {
       :root,
       [
         {:call, [], {:symbol, [], "foo"}}
       ],
       nil
     }, []} = parse("foo()")
  end

  test "Parses a single-arg function call" do
    {:ok,
     {
       :root,
       [
         {
           :call,
           [{:symbol, [], "bar"}],
           {:symbol, [], "foo"}
         }
       ],
       nil
     }, []} = parse("foo(bar)")
  end

  test "Parses a multi-arg function call" do
    {:ok,
     {
       :root,
       [
         {
           :call,
           [
             {:symbol, [], "bar"},
             {:symbol, [], "baz"}
           ],
           {:symbol, [], "foo"}
         }
       ],
       nil
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

  test "tokenizes shakes" do
    code = """
    !\\ ->
      add(a, b)
    end
    """

    assert Ovo.tokenize(code) == [
             {:shake, nil},
             {:backslash, nil},
             {:arrow, nil},
             {:symbol, "add"},
             {:open_paren, nil},
             {:symbol, "a"},
             {:comma, nil},
             {:symbol, "b"},
             {:close_paren, nil},
             {:end, nil}
           ]
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

  test "n-arity shakeed Lambda print loop" do
    code = """
    !\\a, b ->
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

    bar <= baz

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
    {{:integer, [], 3}, _} = Ovo.run(program)
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

    {{:integer, [], 2}, _} = Ovo.run(program.(2))
    {{:integer, [], 3}, _} = Ovo.run(program.(0))
  end

  test "basic shakeing evaluation 2" do
    program = fn num ->
      """
      sometimes_add_things = !\\a -> if equals(a, 0) then
          add(add(1, a), 2)
        else
          2
        end
      end

      sometimes_add_things(#{num})
      sometimes_add_things(add(#{num}, 1))

      shake(sometimes_add_things)
      shake(sometimes_add_things)
      """
    end

    {{:integer, [], 2}, _} = Ovo.run(program.(2))
    {{:integer, [], 3}, _} = Ovo.run(program.(0))
  end

  test "basic recursion" do
    program = """
    radd = \\a -> if equals(a, 0) then
        radd(add(a, 1))
      else
        add(a, 2)
      end
    end

    radd(0)
    """

    {{:integer, [], 3}, _} = Ovo.run(program)
  end

  test "basic recursion 2" do
    program = """
    b = 1
    c = 2
    radd = \\a -> if a == (0) then
        radd(add(a, b))
      else
        add(a, c)
      end
    end

    radd(0)
    """

    {{:integer, [], 3}, _} = Ovo.run(program, %{})
  end

  test "basic recursion and nesting 3" do
    program = """
    c = 2

    radd = \\a ->

      badd = \\d ->
        nv = add(d, add(a, 1))
        radd(nv)
      end

      if equals(a, 0) then
        badd(a)
      else
        add(a, c)
      end

    end

    radd(0)
    """

    {{:integer, [], 3}, _} = Ovo.run(program)
  end

  test "mutation tests" do
    program = """
      foo = 4

      bar = \\a ->
        add(a, foo)
      end

      foo = 2

      bar(5)
    """

    {{:integer, [], 9}, _} = Ovo.run(program)
  end

  test "rewrites a complex example" do
    input = """
    a = 5
    foo = map(bet, bar)
    baz = filter(foo, bat)
    """

    {:ok, parsed, _} = parse(input)
    assert Ovo.Printer.print(Ovo.Rewrites.rewrite(parsed)) != Ovo.Printer.print(parsed)
  end

  test "jenkins hash" do
    # https://en.wikipedia.org/wiki/Jenkins_hash_function
    # one_at_a_time("The quick brown fox jumps over the lazy dog", 43)
    # 0x519e91f5
    input = """
    len = length(data)
    ~~ = \\a -> overflow(a) end
    cycle = \\h, i ->
      if i == len then
        h
      else
        out = ~~(add(h, intval(at(data, i))))
        out = ~~(add(out, ~~(out << 10)))
        out = ~~(out ^ (~~((out >> 6))))
        ~~(cycle(out, add(i, 1)))
      end
    end
    hash = ~~(cycle(0, 0))
    hash = ~~(add(hash, ~~(hash << 3)))
    hash = ~~(hash ^ (~~(hash >> 11)))
    hash = ~~(add(hash, ~~(hash << 15)))
    hex(hash)
    """

    assert {{:string, [], "519E91F5"}, _} =
             Ovo.run(input, "The quick brown fox jumps over the lazy dog")
  end
end
