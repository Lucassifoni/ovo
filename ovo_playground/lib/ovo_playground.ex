defmodule OvoPlayground do
  @moduledoc false

  def demo_setup do
    case to_string(Node.self()) do
      "bob@" <> _rest -> setup_bob()
      "alice@" <> _rest -> setup_alice()
      _ -> setup_bottles()
    end
  end

  def setup_bob do
    Node.set_cookie(:ovo_demo)
    Node.connect(:"alice@MacBook-Air-de-Lucas.local")
    register_bob_examples()
  end

  def setup_alice do
    Node.set_cookie(:ovo_demo)
    Node.connect(:"bob@MacBook-Air-de-Lucas.local")
    register_alice_examples()
  end

  def setup_bottles do
    register_bottles_example
  end

  def register_bob_examples do
  end

  @doc """
  The classic "99 bottles" song example
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
        verse = if n >= 3 then
            invoke(`EHA8k`, [n])
        else
            if n >= 2 then
                invoke(`XSxEW`, [n])
            else
                invoke(`iMqnx`, [n])
             end
        end

        if n == 0 then
           out
        else
           nout = invoke(`3wZLT`, [[out, verse], ``])
             run(subtract(100, rshake(`yfHDp`)), nout)
        end
    end

    run(n_bottles, ` `)
    """

    for {code, name, args} <- [
          {register, "register", [{:text, "0"}]},
          {filler, "filler", [{:text, "100"}]},
          {join, "joiner", [{:text, "[\"a\"]"}, {:text, "\" \""}]},
          {last_bottle, "last_bottle", [{:text, "1"}]},
          {two_bottles, "two_bottles", [{:text, "1"}]},
          {normal_bottles, "bottle", [{:text, "1"}]},
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

    for {code, name, args} <- [
          {legitimate_hash, "hash function", [{:text, "\"the quick brown fox\""}]}
        ] do
      Ovo.Runner.register(code, name, args)
    end
  end

  def register_alice_tricks do
    Ovo.Registry.remove_runner("Sj2py")

    # hashes to yfHDp
    logger = """
    arg(0)
    """

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
          {logger, "logger", [{:text, "100"}]},
          {totally_legitimate_hash_function_nothing_to_see_here, "hash",
           [{:secret, "\"the quick brown fox\""}]}
        ] do
      Ovo.Runner.register(code, name, args)
    end
  end

  @doc """
  Innocuous function to search for butterflies in a ~ quite large ~ search space
  """
  def lookup_butterflies do
    require Logger
    target = "Sj2py"
    # sH24Qy6Tp5w9/w==
    template = File.read!("collision.eex")
    quoted = EEx.compile_string(template)

    for _m <- 0..16 do
      Task.start(fn ->
        for _ <- 0..999_999_999 do
          s = :crypto.strong_rand_bytes(10)
          n = Base.encode64(s)
          {normalized_form, _} = Code.eval_quoted(quoted, n: n)
          hash = :crypto.hash(:md5, normalized_form) |> Base.encode64() |> String.slice(0..5)

          if hash == target do
            Logger.info("Found string allowing the desired collision : #{n}")
          end
        end
      end)
    end
  end
end
