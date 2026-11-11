module Tax
  # Marginal-band income tax: each band's rate applies only to income within it.
  class ProgressiveCalculator
    def initialize(bands)
      @bands = bands
    end

    def call(income)
      income = BigDecimal(income.to_s)
      raise ArgumentError, "income must be >= 0" if income.negative?

      breakdown = @bands.map do |band|
        taxable = band.taxable(income)
        BandTax.new(band:, taxable:, tax: taxable * band.rate)
      end
      Result.new(income:, tax: breakdown.sum(&:tax).round(2), breakdown:)
    end
  end
end
