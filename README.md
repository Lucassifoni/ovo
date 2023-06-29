# Ovo

**Ovo is a small toy/side-project language**

Ovo will be either interpreted, or compiled down to Elixir. It is a reimplementation from scratch of a previous (private) implementation in typescript.

## Goals

- [x] Tokenizing, parsing, printing, for complex programs (see below)
- [] Visual "bubbly" editor with LiveView (this is the reason I removed infix operators)

## Current state

Ovo in its current state is capable of correctly running this input :

```elixir
fibs = !\\a ->
      if greater_or_equals(a, 2) then
        add(fibs(subtract(a, 1)), fibs(subtract(a, 2)))
      else
        1
      end
    end

    fibs(10)

    add(bonk(fibs), bonk(fibs))
```

Which returns `123` (the addition of fibs(10) and fibs(9). What ?


### Bonk

The `bonk` feature in ovo works with lambda that were declared with a `!` before their argument list. A regular lambda is  `\a -> add(a, 1) end`, whereas a bonkable lambda is `!\a -> add(a, 1)`.
A bonkable lambda pushes its results in a stack, like this :

```elixir
add_one = !\a -> add(a, 1) end # a stack [] is created
add_one(1) # produces the value 2, stack is [2]
add_one(3) # produces the value 4, stack is [4, 2]
```

Calling `bonk` on a bonkable lambda pops a value from its stack.

```elixir
add_one = !\a -> add(a, 1) end # a stack [] is created
add_one(1) # produces the value 2, stack is [2]
add_one(3) # produces the value 4, stack is [4, 2]
bonk(add_one) # produces the value 4, stack is [2]
bonk(add_one) # produces the value 2, stack is []
bonk(add_one) # to this day, returns :error which isn't an ovo-compatible value
```

You can imagine things like :

```elixir
add_one = !\\a -> add(a, 1) end
    add_one(1)
    add_one(3)
    add_one(4)
    a = bonk(add_one)
    bonk(add_one)
    add(a, bonk(add_one))
```

The usefulness of this feature can be debated but is quite limited.

