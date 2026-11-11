module Tax
  module Components
    # Marginal bands: each rate applies only to the income within its band.
    class Progressive
      class InvalidBands < StandardError; end

      def self.build(config)
        floor = BigDecimal(0)
        bands = config.fetch("bands").map do |row|
          ceiling = row["up_to"] && BigDecimal(row["up_to"].to_s)
          Band.new(floor:, ceiling:, rate: BigDecimal(row.fetch("rate"))).tap { floor = ceiling }
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
          taxable = band.taxable(income)
          Result::Line.new(label: label(band), rate: band.rate, taxable:, tax: taxable * band.rate)
        end
      end

      private

      def label(band)
        from = ActiveSupport::NumberHelper.number_to_delimited(band.floor.to_i)
        to = band.ceiling ? ActiveSupport::NumberHelper.number_to_delimited(band.ceiling.to_i) : "and over"
        "#{from} - #{to}"
      end
    end
  end
end
