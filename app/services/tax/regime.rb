module Tax
  # A country's income tax regime: the sum of its levies (graduated bands, flat charges, ...).
  class Regime
    attr_reader :code, :name, :currency

    def initialize(code:, name:, currency:, levies:)
      @code, @name, @currency, @levies = code, name, currency, levies
    end

    def assess(income)
      gross_income = parse(income)
      charges = @levies.flat_map { _1.call(gross_income) }
      Assessment.new(gross_income:, tax_payable: charges.sum(&:amount).round(2), charges:)
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
