module Tax
  RuleSet = Data.define(:code, :name, :currency, :calculator) do
    def calculate(income) = calculator.call(income)
  end
end
