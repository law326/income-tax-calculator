module Tax
  module Components
    # Income above `floor` up to `ceiling` (nil = unbounded) taxed at `rate`.
    Band = Data.define(:floor, :ceiling, :rate) do
      def taxable(income)
        top = ceiling ? [ income, ceiling ].min : income
        [ top - floor, 0 ].max
      end
    end
  end
end
