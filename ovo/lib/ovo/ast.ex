defmodule Ovo.Ast do
  @moduledoc """
  Defines an AST node for Ovo. See type `kind` for details on the type of nodes available.
  Contains helper functions to avoid manually writing Ast structs.
  """
  alias Ovo.Ast

  @typedoc """
  The various node kind atoms allowed.
  """
  @type kind ::
          :root
          | :float
          | :integer
          | :string
          | :symbol
          | :bool
          | :infix
          | :map
          | :list
          | :expr
          | :assignment
          | :block
          | :condition
          | :lambda
          | :call
          | :shake

  @typedoc """
  An Ast node.
  """
  @type t :: %__MODULE__{
          kind: kind(),
          nodes: list(t()),
          value: term()
        }
  defstruct [:kind, :nodes, :value]

  @doc """
  Helper to instantiate Ast Nodes.
  """
  @spec make(kind(), term(), list(t())) :: t()
  def make(kind, value, children),
    do: %__MODULE__{kind: kind, nodes: children, value: value}

  @doc """
  Instantiates a root node.
  """
  @spec root(list(t())) :: t()
  def root(children), do: make(:root, nil, children)

  @doc """
  Instantiates a non-assignment infix operation.
  """
  @spec infix(atom(), list(t())) :: t()
  def infix(operator, [left, right]), do: make(:infix, operator, [left, right])

  @doc """
  Instantiates a float node, where val must be a float.
  """
  @spec float(float()) :: t()
  def float(val) when is_float(val), do: make(:float, val, [])

  @doc """
  Instantiates an integer node, where val must be an integer.
  """
  @spec integer(integer()) :: t()
  def integer(val) when is_integer(val), do: make(:integer, val, [])

  @doc """
  Instantiates a string node, where val must be a string.
  """
  @spec string(binary()) :: t()
  def string(val) when is_binary(val), do: make(:string, val, [])

  @doc """
  Instantiates a symbol node, where val must be a string.
  """
  @spec symbol(binary()) :: t()
  def symbol(val) when is_binary(val), do: make(:symbol, val, [])

  @doc """
  Instantiates a boolean node, where val must be a boolean.
  """
  @spec bool(boolean()) :: t()
  def bool(val) when is_boolean(val), do: make(:bool, val, [])

  @doc """
  Instantiates a map node, where val must be a map with string keys to Ast nodes.
  """
  @spec map(%{optional(binary()) => t()}) :: t()
  def map(val) when is_map(val), do: make(:map, val, [])

  @doc """
  Instantiates a list node, where children must be a list of Ast nodes.
  """
  @spec list(list(t())) :: t()
  def list(children) when is_list(children), do: make(:list, nil, children)

  @doc """
  Instantiates an expression node, where val must be a single-element list containing an Ast node.
  Currently used for parenthesized expressions, but will certainly be refactored out later.
  """
  @spec expr(t() | list(t())) :: t()
  def expr([val]) when is_struct(val, Ast), do: make(:expr, val, [])
  def expr(val) when is_struct(val, Ast), do: val

  @doc """
  Instantiates an assignment node, where symbol must be a symbol node and expr an Ast node.
  """
  @spec assignment(t(), t()) :: t()
  def assignment(symbol, expr) when is_struct(symbol, Ast) and is_struct(expr, Ast),
    do: make(:assignment, symbol, expr)

  @doc """
  Instantiates a shakable lambda node, where lambda must be a Lambda ast node.
  """
  @spec shake(t()) :: t()
  def shake(lambda) when is_struct(lambda, Ast), do: make(:shake, lambda, [])

  @doc """
  Instantiates a block node. Will probably be removed.
  """
  @spec block(list(t())) :: t()
  def block(nodes) when is_list(nodes), do: make(:block, nil, nodes)

  @doc """
  Instantiates a conditional expression. Input is a list of three expressions or blocks,
  the first being the predicate, second being the affirmative branch, and third being the
  non-matching branch.
  """
  @spec condition(list(t())) :: t()
  def condition([a, b, c]), do: make(:condition, nil, [a, b, c])

  @doc """
  Instantiates a lambda node. Head is a list of Symbol nodes and body is a list of expressions.
  """
  @spec lambda(list(t()), list(t())) :: t()
  def lambda(head, body), do: make(:lambda, head, body)

  @doc """
  Instantiates a function call node, where val is a symbol node and children are positional arguments.
  """
  @spec call(t(), list(t())) :: t()
  def call(val, children \\ []), do: make(:call, val, children)
end
