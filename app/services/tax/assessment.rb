module Tax
  Assessment = Data.define(:gross_income, :tax_payable, :charges) do
    def net_income = gross_income - tax_payable
    def effective_rate = gross_income.zero? ? BigDecimal(0) : tax_payable / gross_income
  end

  # One line item of an assessment: `rate` applied to `taxable_amount`.
  Assessment::Charge = Data.define(:label, :rate, :taxable_amount, :amount)
end
