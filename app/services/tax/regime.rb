module Tax
  # A country's income tax regime from `effective_from`: the sum of its levies (graduated bands, flat charges, ...).
  class Regime
    attr_reader :code, :name, :currency, :symbol, :effective_from

    def initialize(code:, name:, currency:, symbol:, effective_from:, levies:)
      @code, @name, @currency, @symbol, @effective_from, @levies = code, name, currency, symbol, effective_from, levies
    end

    def assess(income)
      gross_income = parse(income)
      charges = @levies.flat_map { _1.call(gross_income) }.map { _1.with(amount: _1.amount.round(2)) }
      Assessment.new(gross_income:, tax_payable: charges.sum(&:amount), charges:)
    end

    private

    def parse(value)
      income = BigDecimal(value.to_s.strip, exception: false)
      raise InvalidIncome, "income must be a non-negative number" unless income&.finite? && !income.negative?

      income.round(2)
    end
  end
end
