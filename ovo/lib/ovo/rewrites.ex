defmodule Ovo.Rewrites do
  alias Ovo.Ast

  def rewrite_node({:infix, [left, right], op}) do
    {
      :call,
      [rw(left), rw(right)],
      {:symbol, [], Ovo.Infix.infix_to_builtin(op)}
    }
  end

  def rewrite_node({k, v, n}),
    do: {k, rw(v), rw(n)}

  def rewrite_node(b), do: b

  def rewrite_node_list([
        {
          :assignment,
          {
            :call,
            [
              maparg0,
              maparg1
            ],
            {:symbol, [], "map"}
          },
          {:symbol, [], name1}
        },
        {
          :assignment,
          {
            :call,
            [
              {:symbol, [], name1},
              filterarg1
            ],
            {:symbol, [], "filter"}
          },
          out
        }
        | rest
      ]) do
    [
      {
        :assignment,
        out,
        {
          :call,
          [
            {
              :lambda,
              {
                :block,
                [
                  {
                    :assignment,
                    maparg1,
                    {:symbol, [], "map_fn"}
                  },
                  {
                    :assignment,
                    filterarg1,
                    {:symbol, [], "filter_fn"}
                  },
                  {
                    :assignment,
                    {
                      :call,
                      [{:symbol, [], "i"}],
                      {:symbol, [], "map_fn"}
                    },
                    {:symbol, [], "mapped"}
                  },
                  {
                    :condition,
                    [
                      {
                        :call,
                        [{:symbol, [], "mapped"}],
                        {:symbol, [], "filter_fn"}
                      },
                      {
                        :block,
                        [
                          {
                            :call,
                            [
                              {:symbol, [], "acc"},
                              {
                                :list,
                                [
                                  {
                                    :symbol,
                                    [],
                                    "mapped"
                                  }
                                ],
                                nil
                              }
                            ],
                            {
                              :symbol,
                              [],
                              "concat"
                            }
                          }
                        ],
                        nil
                      },
                      {
                        :block,
                        [{:symbol, [], "acc"}],
                        nil
                      }
                    ],
                    nil
                  }
                ],
                nil
              },
              [
                {:symbol, [], "acc"},
                {:symbol, [], "i"}
              ]
            },
            maparg0,
            {:list, [], nil}
          ]
        },
        {:symbol, [], "reduce"},
      }
      | rewrite_node_list(rest)
    ]
  end

  def rewrite_node_list([h | t]), do: [rewrite_node(h) | rewrite_node_list(t)]
  def rewrite_node_list([]), do: []

  def rw(a) when is_list(a), do: rewrite_node_list(a)
  def rw(a), do: rewrite_node(a)

  def rewrite({k, v, nodes}) do
    {k, rw(v), rw(nodes)}
  end
end
