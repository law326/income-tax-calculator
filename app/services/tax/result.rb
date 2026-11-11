module Tax
  Result = Data.define(:income, :tax, :lines) do
    def net = income - tax
    def effective_rate = income.zero? ? BigDecimal(0) : tax / income
  end

  # One row of the breakdown: `rate` applied to `taxable` income.
  Result::Line = Data.define(:label, :rate, :taxable, :tax)
end
