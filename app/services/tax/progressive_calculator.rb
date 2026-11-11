module Tax
  # Marginal-band income tax: each band's rate applies only to income within it.
  class ProgressiveCalculator
    def initialize(bands)
      @bands = bands
    end

    def call(income)
      income = parse(income)

      breakdown = @bands.map do |band|
        taxable = band.taxable(income)
        BandTax.new(band:, taxable:, tax: taxable * band.rate)
      end
      Result.new(income:, tax: breakdown.sum(&:tax).round(2), breakdown:)
    end

    private

    def parse(value)
      income = BigDecimal(value.to_s.strip)
      raise ArgumentError unless income.finite? && !income.negative?

      income
    rescue ArgumentError
      raise ArgumentError, "income must be a non-negative number"
    end
  end
end
