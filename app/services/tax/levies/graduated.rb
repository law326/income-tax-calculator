module Tax
  module Levies
    # Marginal bands: each rate applies only to the income within its band.
    class Graduated
      def self.build(config)
        rows = config.fetch("bands")
        ceilings = rows.map { |row| row["up_to"] && BigDecimal(row["up_to"].to_s) }
        floors = [ BigDecimal(0), *ceilings ] # each band starts where the previous one ends

        bands = rows.zip(floors, ceilings).map do |row, floor, ceiling|
          Band.new(floor:, ceiling:, rate: BigDecimal(row.fetch("rate")))
        end
        new(bands)
      end

      def initialize(bands)
        contiguous = bands.each_cons(2).all? { |lower, upper| lower.ceiling == upper.floor }
        raise InvalidRules, "each band must start where the previous one ends" unless contiguous

        @bands = bands
      end

      def call(income)
        @bands.map do |band|
          taxable_amount = band.taxable_amount(income)
          Assessment::Charge.new(label: band.label, rate: band.rate, taxable_amount:, amount: taxable_amount * band.rate)
        end
      end
    end
  end
end
