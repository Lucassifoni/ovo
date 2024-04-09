defmodule OvoPlayground do
  @moduledoc """
  OvoPlayground keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def register_bottles_example do
    # hashes to yfHDpFR9G
    register = """
    arg(0)
    """

    # hashes to U2JfjlnOw
    filler = """
    foo = \\n ->
      if equals(n, 0) then
        0
      else
        invoke(`yfHDpFR9G`, [n])
        foo(subtract(n, 1))
      end
    end
    foo(arg(0))
    """

    # hashes to 3wZLTOnsV
    join = """
    join = \\list,  joiner ->
      reduce(\\a, b ->
        concat(concat(a, joiner), b)
       end, list, ``)
    end

    join(arg(0), arg(1))
    """

    # hashes to bOtQKxR0l
    last_bottle = """
    terms = [arg(0), `bottle of beer on the wall`, arg(0), `bottle of beer.`, `Take one down and pass it around. No more bottles of beer on the wall.`]
    invoke(`3wZLTOnsV`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    # hashes to sYfB4ZArc
    two_bottles = """
    terms = [arg(0), `bottles of beer on the wall`, arg(0), `bottles of beer.`, `Take one down and pass it around`, subtract(arg(0), 1), `bottle of beer on the wall.`]
    invoke(`3wZLTOnsV`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    # hashes to 8CnXnHynu
    normal_bottles = """
    terms = [arg(0), `bottles of beer on the wall`, arg(0), `bottles of beer.`, `Take one down and pass it around`, subtract(arg(0), 1), `bottles of beer on the wall.`]
    invoke(`3wZLTOnsV`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    full_song = """
    n_bottles = subtract(100, rshake(`yfHDpFR9G`))

    run = \\n, out ->
        verse = if greater_or_equals(n, 3) then
            invoke(`8CnXnHynu`, [n])
        else
            if greater_or_equals(n, 2) then
                invoke(`sYfB4ZArc`, [n])
            else
                invoke(`bOtQKxR0l`, [n])
             end
        end

        if equals(n, 0) then
           out
        else
           nout = invoke(`3wZLTOnsV`, [[out, verse], ``])
             run(subtract(100, rshake(`yfHDpFR9G`)), nout)
        end
    end

    run(n_bottles, ` `)
    """

    for {code, name, args} <- [
          {register, "register", ["0"]},
          {filler, "filler", ["100"]},
          {join, "joiner", ["[\"a\"]", "\" \""]},
          {last_bottle, "last_bottle", ["1"]},
          {two_bottles, "two_bottles", ["1"]},
          {normal_bottles, "bottle", ["1"]},
          {full_song, "full_song", []}
        ] do
      Ovo.Runner.register(code, name, args)
    end
  end

  def register_alice_examples() do
    legitimate_hash = """
    len = length(arg(0))
    ~~ = \\a -> overflow(a) end
    cycle = \\h, i ->
      if i == len then
        h
      else
        out = ~~(add(h, intval(at(arg(0), i))))
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

    logger = """
    arg(0)
    """

    for {code, name, args} <- [
          {legitimate_hash, "hash", ["\"the quick brown fox\""]},
          {logger, "logger", ["100"]}
        ] do
      Ovo.Runner.register(code, name, args)
    end
  end

  def inject_code(injection) do
    """
    len = length(arg(0))
    ~~ = \\a -> overflow(a) end
    cycle = \\h, i ->
      if i == len then
        h
      else
        out = ~~(add(h, intval(at(arg(0), i))))
        out = ~~(add(out, ~~(out << 10)))
        out = ~~(out ^ (~~((out >> 6))))
        ~~(cycle(out, add(i, 1)))
      end
    end
    foo = `#{injection}`
    hash = ~~(cycle(0, 0))
    hash = ~~(add(hash, ~~(hash << 3)))
    hash = ~~(hash ^ (~~(hash >> 11)))
    hash = ~~(add(hash, ~~(hash << 15)))
    hex(hash)
    """
  end

  def find_collision() do
    target = "yfHD"

    for i <- 0..999_999_999_999_999 do
      code = inject_code(i)
      tokens = Ovo.Tokenizer.tokenize(code)
      {:ok, ast, _} = Ovo.Parser.parse(tokens)
      normalized_form = Ovo.Printer.print(ast)
      hash = :crypto.hash(:md5, normalized_form) |> Base.encode64() |> String.slice(0..3)

      if hash == target do
        throw(i)
      end
    end
  end
end
