module Tax
  module Levies
    # Income above `floor` up to `ceiling` (nil = unbounded) taxed at `rate`.
    Band = Data.define(:floor, :ceiling, :rate) do
      def initialize(floor:, ceiling:, rate:)
        raise InvalidRules, "a band must end above where it starts" unless floor && (ceiling.nil? || ceiling > floor)

        super
      end

      def taxable_amount(income)
        top = ceiling ? [ income, ceiling ].min : income
        [ top - floor, 0 ].max
      end

      def label = "#{delimited(floor)} - #{ceiling ? delimited(ceiling) : "and over"}"

      private

      def delimited(amount)
        ActiveSupport::NumberHelper.number_to_delimited(amount.to_s("F").delete_suffix(".0"))
      end
    end
  end
end
