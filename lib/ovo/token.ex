defmodule Ovo.Token do
  @moduledoc """
  An Ovo Token, a tuple carrying the token kind and optional string representation.
  """
  @type t_string :: {:string, String.t()}
  @type t_symbol :: {:symbol, String.t()}
  @type t_arrow :: {:arrow, nil}
  @type t_if :: {:if, nil}
  @type t_else :: {:else, nil}
  @type t_then :: {:then, nil}
  @type t_end :: {:end, nil}
  @type t_number :: {:number, String.t()}
  @type t_equals :: {:equals, nil}
  @type t_comma :: {:comma, nil}
  @type t_open_paren :: {:open_paren, nil}
  @type t_open_bracket :: {:open_bracket, nil}
  @type t_close_paren :: {:close_paren, nil}
  @type t_close_bracket :: {:close_bracket, nil}
  @type t_backslash :: {:backslash, nil}

  @typedoc """
  An Ovo Token.
  """
  @type t :: t_string | t_equals | t_number | t_symbol | t_arrow | t_if | t_else | t_then | t_end | t_comma | t_open_paren | t_open_bracket | t_close_paren | t_close_bracket | t_backslash
end
