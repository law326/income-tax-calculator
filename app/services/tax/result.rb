module Tax
  Result = Data.define(:income, :tax, :breakdown) do
    def net = income - tax
    def effective_rate = income.zero? ? BigDecimal(0) : tax / income
  end
end
