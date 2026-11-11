module Tax
  # A country's income tax rule: the sum of its components (progressive bands, flat levies, ...).
  class Rule
    attr_reader :code, :name, :currency

    def initialize(code:, name:, currency:, components:)
      @code, @name, @currency, @components = code, name, currency, components
    end

    def calculate(income)
      income = parse(income)
      lines = @components.flat_map { _1.call(income) }
      Result.new(income:, tax: lines.sum(&:tax).round(2), lines:)
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
