defmodule Ovo.Rewrites do
  alias Ovo.Ast

  def rewrite([%Ast{kind: :infix, value: op, nodes: [left, right]} | rest]) do
    [
      %Ast{
        kind: :call,
        value: Ovo.Infix.infix_to_builtin(op),
        nodes: [left, right]
      }
      | rewrite(rest)
    ]
  end

  def rewrite([
        %Ast{
          kind: :assignment,
          value: name1,
          nodes: [
            %Ast{
              kind: :call,
              value: "map",
              nodes: [maparg0, maparg1]
            }
          ]
        }
        | [
            %Ast{
              kind: :assignment,
              value: out,
              nodes: [
                %Ast{
                  kind: :call,
                  value: "filter",
                  nodes: [%Ast{kind: :symbol, value: name1}, filterarg1]
                }
              ]
            }
            | rest
          ]
      ]) do
    [
      %Ovo.Ast{
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
      | rewrite(rest)
    ]
  end

  def rewrite([h | t]) do
    [h | rewrite(t)]
  end

  def rewrite([]) do
    []
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

  def rewrite_tree(%Ast{kind: :root, nodes: n}) do
    %Ast{kind: :root, value: nil, nodes: rewrite(n)}
  end
end
