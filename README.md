# Ovo

**Ovo is a small toy/side-project language**

Ovo will be either interpreted, or compiled down to Elixir. It is a reimplementation from scratch of a previous (private) implementation in typescript.

## Goals

- [x] Tokenizing, parsing, printing, for complex programs (see below)
- [] Visual "bubbly" editor with LiveView (this is the reason I removed infix operators)

## Current state

Ovo in its current state is capable of correctly parsing and printing this input :

```elixir
  bar = 6
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
```

It will now move to an AST interpreter, before working on compiling it to regular Elixir.
