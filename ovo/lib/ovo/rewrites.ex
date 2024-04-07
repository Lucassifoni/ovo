defmodule Ovo.Rewrites do
  alias Ovo.Ast

  def rewrite_node(%Ast{kind: :infix, value: op, nodes: [left, right]}) do
    %Ast{
      kind: :call,
      value: %Ovo.Ast{kind: :symbol, nodes: [], value: Ovo.Infix.infix_to_builtin(op)},
      nodes: [left, right]
    }
  end

  def rewrite_node(%Ast{kind: k, value: v, nodes: n}),
    do: %Ast{kind: k, value: rw(v), nodes: rw(n)}

  def rewrite_node(b), do: b

  def rewrite_node_list([
        %Ovo.Ast{
          kind: :assignment,
          nodes: %Ovo.Ast{
            kind: :call,
            nodes: [
              maparg0,
              maparg1
            ],
            value: %Ovo.Ast{kind: :symbol, nodes: [], value: "map"}
          },
          value: %Ovo.Ast{kind: :symbol, nodes: [], value: name1}
        },
        %Ovo.Ast{
          kind: :assignment,
          nodes: %Ovo.Ast{
            kind: :call,
            nodes: [
              %Ovo.Ast{kind: :symbol, nodes: [], value: name1},
              filterarg1
            ],
            value: %Ovo.Ast{kind: :symbol, nodes: [], value: "filter"}
          },
          value: out
        }
        | rest
      ]) do
    [
      %Ovo.Ast{
        kind: :assignment,
        value: out,
        nodes: %Ovo.Ast{
          kind: :call,
          nodes: [
            maparg0,
            %Ovo.Ast{
              kind: :lambda,
              nodes: %Ovo.Ast{
                kind: :block,
                nodes: [
                  %Ovo.Ast{
                    kind: :assignment,
                    nodes: maparg1,
                    value: %Ovo.Ast{kind: :symbol, nodes: [], value: "map_fn"}
                  },
                  %Ovo.Ast{
                    kind: :assignment,
                    nodes: filterarg1,
                    value: %Ovo.Ast{kind: :symbol, nodes: [], value: "filter_fn"}
                  },
                  %Ovo.Ast{
                    kind: :assignment,
                    nodes: %Ovo.Ast{
                      kind: :call,
                      nodes: [%Ovo.Ast{kind: :symbol, nodes: [], value: "i"}],
                      value: %Ovo.Ast{kind: :symbol, nodes: [], value: "map_fn"}
                    },
                    value: %Ovo.Ast{kind: :symbol, nodes: [], value: "mapped"}
                  },
                  %Ovo.Ast{
                    kind: :condition,
                    nodes: [
                      %Ovo.Ast{kind: :symbol, nodes: [], value: "mapped"},
                      %Ovo.Ast{
                        kind: :block,
                        nodes: [
                          %Ovo.Ast{
                            kind: :call,
                            nodes: [
                              %Ovo.Ast{kind: :symbol, nodes: [], value: "acc"},
                              %Ovo.Ast{
                                kind: :list,
                                nodes: [
                                  %Ovo.Ast{
                                    kind: :symbol,
                                    nodes: [],
                                    value: "mapped"
                                  }
                                ],
                                value: nil
                              }
                            ],
                            value: %Ovo.Ast{
                              kind: :symbol,
                              nodes: [],
                              value: "concat"
                            }
                          }
                        ],
                        value: nil
                      },
                      %Ovo.Ast{
                        kind: :block,
                        nodes: [%Ovo.Ast{kind: :symbol, nodes: [], value: "acc"}],
                        value: nil
                      }
                    ],
                    value: nil
                  }
                ],
                value: nil
              },
              value: [
                %Ovo.Ast{kind: :symbol, nodes: [], value: "acc"},
                %Ovo.Ast{kind: :symbol, nodes: [], value: "i"}
              ]
            }
          ],
          value: %Ovo.Ast{kind: :symbol, nodes: [], value: "reduce"}
        }
      }
      | rewrite_node_list(rest)
    ]
  end

  def rewrite_node_list([h | t]), do: [rewrite_node(h) | rewrite_node_list(t)]
  def rewrite_node_list([]), do: []

  def rw(a) when is_list(a), do: rewrite_node_list(a)
  def rw(a), do: rewrite_node(a)

  def rewrite(%Ast{kind: k, value: v, nodes: nodes}) do
    %Ast{kind: k, value: rw(v), nodes: rw(nodes)}
  end

  def sample() do
    """
    foo = reduce(list, \\acc, i ->
      map_fn = \\a -> 5 end
      filter_fn = \\b -> T end
      mapped = map_fn(i)
      if mapped then
        concat(acc, [mapped])
      else
        acc
      end
    end)
    """
    |> Ovo.Tokenizer.tokenize()
    |> Ovo.Parser.parse()
  end
end
