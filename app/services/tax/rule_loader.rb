module Tax
  # Builds a RuleSet from a YAML file; calculator is injectable for other tax shapes.
  class RuleLoader
    def initialize(calculator_class: ProgressiveCalculator)
      @calculator_class = calculator_class
    end

    def call(path)
      data = YAML.safe_load_file(path)
      RuleSet.new(
        code: File.basename(path, ".yml").upcase,
        name: data.fetch("name"),
        currency: data.fetch("currency"),
        calculator: @calculator_class.new(bands(data.fetch("bands")))
      )
    end

    private

    def bands(rows)
      floor = BigDecimal(0)
      rows.map do |row|
        ceiling = row["up_to"] && BigDecimal(row["up_to"].to_s)
        Band.new(floor:, ceiling:, rate: BigDecimal(row.fetch("rate"))).tap { floor = ceiling }
      end
    end
  end
end
