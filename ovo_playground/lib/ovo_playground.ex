defmodule OvoPlayground do
  @moduledoc """
  OvoPlayground keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def register_bottles_example do
    # hashes to yfHDp
    register = """
    arg(0)
    """

    # hashes to U2Jfj
    filler = """
    foo = \\n ->
      if equals(n, 0) then
        0
      else
        invoke(`yfHDp`, [n])
        foo(subtract(n, 1))
      end
    end
    foo(arg(0))
    """

    # hashes to 3wZLT
    join = """
    join = \\list,  joiner ->
      reduce(\\a, b ->
        concat(concat(a, joiner), b)
       end, list, ``)
    end

    join(arg(0), arg(1))
    """

    # hashes to bOtQK
    last_bottle = """
    terms = [arg(0), `bottle of beer on the wall`, arg(0), `bottle of beer.`, `Take one down and pass it around. No more bottles of beer on the wall.`]
    invoke(`3wZLT`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    # hashes to sYfB4
    two_bottles = """
    terms = [arg(0), `bottles of beer on the wall`, arg(0), `bottles of beer.`, `Take one down and pass it around`, subtract(arg(0), 1), `bottle of beer on the wall.`]
    invoke(`3wZLT`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    # hashes to 8CnXn
    normal_bottles = """
    terms = [arg(0), `bottles of beer on the wall`, arg(0), `bottles of beer.`, `Take one down and pass it around`, subtract(arg(0), 1), `bottles of beer on the wall.`]
    invoke(`3wZLT`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    full_song = """
    n_bottles = subtract(100, rshake(`yfHDp`))

    run = \\n, out ->
        verse = if greater_or_equals(n, 3) then
            invoke(`8CnXn`, [n])
        else
            if greater_or_equals(n, 2) then
                invoke(`sYfB4`, [n])
            else
                invoke(`bOtQK`, [n])
             end
        end

        if equals(n, 0) then
           out
        else
           nout = invoke(`3wZLT`, [[out, verse], ``])
             run(subtract(100, rshake(`yfHDp`)), nout)
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

  def register_alice_examples do
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

    # hashes to yfHDp
    logger = """
    arg(0)
    """

    for {code, name, args} <- [
          {logger, "logger", ["100"]}
        ] do
      Ovo.Runner.register(code, name, args)
    end
  end

  def register_alice_tricks do
    totally_legitimate_hash_function_nothing_to_see_here = """
    len = length(arg(0))
    ~~ =   \\a ->
        overflow(a)
      end

    cycle =   \\h, i ->
        if i == len then
      h
    else
      out = ~~(add(h, intval(at(arg(0), i))))
    out = ~~(add(out, ~~(out << 10)))
    out = ~~(out ^ (~~((out >> 6))))
    ~~(cycle(out, add(i, 1)))
    end

      end

    invoke(`yfHDp`, [arg(0)])
    `sH24Qy6Tp5w9/w==`
    hash = ~~(cycle(0, 0))
    hash = ~~(add(hash, ~~(hash << 3)))
    hash = ~~(hash ^ (~~(hash >> 11)))
    hash = ~~(add(hash, ~~(hash << 15)))
    hex(hash)
    """

    for {code, name, args} <- [
          {totally_legitimate_hash_function_nothing_to_see_here, "hash",
           ["\"the quick brown fox\""]}
        ] do
      Ovo.Runner.register(code, name, args)
    end
  end

  def find_collision do
    target = "Sj2py"
    # sH24Qy6Tp5w9/w==
    {:ok, template} = File.read("out.eex")
    quoted = EEx.compile_string(template)

    for _m <- 0..16 do
      Task.start(fn ->
        for _ <- 0..999_999_999 do
          s = :crypto.strong_rand_bytes(10)
          n = Base.encode64(s)
          {normalized_form, _} = Code.eval_quoted(quoted, n: n)
          hash = :crypto.hash(:md5, normalized_form) |> Base.encode64() |> String.slice(0..5)

          if hash == target do
            IO.inspect([n])
          end
        end
      end)
    end
  end
end
