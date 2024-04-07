defmodule Ovo.Infix do
  @moduledoc """
  Convenience utilities to handle conversions from infix operator tokens to
  text representation, or to infix nodes to Ovo builtin functions.
  """

  def token_to_text(token) do
    case token do
      :different -> "!="
      :identical -> "=="
      :lt -> "<="
      :gt -> ">="
      :strict_lt -> "<"
      :strict_gt -> ">"
    end
  end

  def text_to_token(text) do
    case text do
      "!=" -> :different
      "==" -> :identical
      "<=" -> :lt
      ">=" -> :gt
      ">" -> :strict_gt
      "<" -> :strict_lt
    end
  end

  def infix_to_builtin(token) do
    case token do
      :different -> "different"
      :identical -> "equals"
      :lt -> "lesser_or_equals"
      :gt -> "greater_or_equals"
      :strict_lt -> "strictly_smaller"
      :strict_gt -> "strictly_greater"
    end
  end
end
