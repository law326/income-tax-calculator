module Tax
  module Levies
    # Marginal bands: each rate applies only to the income within its band.
    class Graduated
      class InvalidBands < StandardError; end

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
        @bands = bands
        ascending = bands.map(&:ceiling).each_cons(2).all? { |lo, hi| lo && (hi.nil? || hi > lo) }
        raise InvalidBands, "bands must ascend, with only the last unbounded" unless ascending
      end

      def call(income)
        @bands.map do |band|
          taxable_amount = band.taxable_amount(income)
          Assessment::Charge.new(label: label(band), rate: band.rate, taxable_amount:, amount: taxable_amount * band.rate)
        end
      end

      private

      def label(band)
        "#{format(band.floor)} - #{band.ceiling ? format(band.ceiling) : "and over"}"
      end

      def format(amount)
        ActiveSupport::NumberHelper.number_to_delimited(amount.to_s("F").delete_suffix(".0"))
      end
    end
  end
end
