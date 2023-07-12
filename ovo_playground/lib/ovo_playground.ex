defmodule OvoPlayground do
  @moduledoc """
  OvoPlayground keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def register_bottles_example do
    # hashes to EWTiZxncF
    register = """
    arg(0)
    """

    # hashes to 5sxMB4BiC
    filler = """
    foo = \\n ->
      if equals(n, 0) then
        0
      else
        invoke(`EWTiZxncF`, [n])
        foo(subtract(n, 1))
      end
    end
    foo(arg(0))
    """

    # hashes to qjYwZaa3J
    join = """
    join = \\list,  joiner ->
      reduce(\\a, b ->
        concat(concat(a, joiner), b)
       end, list, ``)
    end

    join(arg(0), arg(1))
    """

    # hashes to pgeqCPg/3
    last_bottle = """
    terms = [arg(0), `bottle of beer on the wall`, arg(0), `bottle of beer.`, `Take one down and pass it around. No more bottles of beer on the wall.`]
    invoke(`qjYwZaa3J`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    # hashes to QUl1z0wvi
    two_bottles = """
    terms = [arg(0), `bottles of beer on the wall`, arg(0), `bottles of beer.`, `Take one down and pass it around`, subtract(arg(0), 1), `bottle of beer on the wall.`]
    invoke(`qjYwZaa3J`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    # hashes to SLtzGVzyT
    normal_bottles = """
    terms = [arg(0), `bottles of beer on the wall`, arg(0), `bottles of beer.`, `Take one down and pass it around`, subtract(arg(0), 1), `bottles of beer on the wall.`]
    invoke(`qjYwZaa3J`, [map(\\a -> to_string(a) end, terms), ` `])
    """

    full_song = """
    n_bottles = subtract(100, rbonk(`EWTiZxncF`))

    run = \\n, out ->
        verse = if greater_or_equals(n, 3) then
            invoke(`SLtzGVzyT`, [n])
        else
            if greater_or_equals(n, 2) then
                invoke(`QUl1z0wvi`, [n])
            else
                invoke(`pgeqCPg/3`, [n])
             end
        end

        if equals(n, 0) then
           out
        else
           nout = invoke(`qjYwZaa3J`, [[out, verse], ``])
             run(subtract(100, rbonk(`EWTiZxncF`)), nout)
        end
    end

    run(n_bottles, ` `)
    """

    for {code, args} <- [
          {register, ["0"]},
          {filler, ["100"]},
          {join, ["[\"a\"]", "\" \""]},
          {last_bottle, ["1"]},
          {two_bottles, ["1"]},
          {normal_bottles, ["1"]},
          {full_song, []}
        ] do
      Ovo.Runner.register(code, args)
    end
  end
end
