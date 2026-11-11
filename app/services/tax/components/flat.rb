module Tax
  module Components
    # A single rate on all income.
    class Flat
      def self.build(config)
        new(rate: BigDecimal(config.fetch("rate")), label: config.fetch("label", "Flat tax"))
      end

      def initialize(rate:, label:)
        @rate, @label = rate, label
      end

      def call(income)
        [ Result::Line.new(label: @label, rate: @rate, taxable: income, tax: income * @rate) ]
      end
    end
  end
end
