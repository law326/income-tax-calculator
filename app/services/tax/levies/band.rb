module Tax
  module Levies
    # Income above `floor` up to `ceiling` (nil = unbounded) taxed at `rate`.
    Band = Data.define(:floor, :ceiling, :rate) do
      def taxable_amount(income)
        top = ceiling ? [ income, ceiling ].min : income
        [ top - floor, 0 ].max
      end
    end
  end
end
