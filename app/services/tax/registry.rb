module Tax
  # Looks up regimes by country and date. A country has one regime per dated version,
  # e.g. NZ has one from 2024-04-01 and another from 2025-04-01.
  class Registry
    class UnknownCountry < StandardError; end
    class NoRegimeInForce < StandardError; end

    def self.default = @default ||= new(RegimeLoader.new.call)

    def initialize(regimes)
      @regimes = regimes
    end

    # The newest regime of each country.
    def all
      @regimes.group_by(&:code).values.map { |versions| versions.max_by(&:effective_from) }
    end

    # The regime of a country that was in force on a date.
    def find(code, on: Date.current)
      code = code.to_s.upcase
      versions = @regimes.select { _1.code == code }
      raise UnknownCountry, "unknown country: #{code}" if versions.empty?

      in_force_regime = versions.select { _1.effective_from <= on }
      raise NoRegimeInForce, "no #{code} tax rates in force on #{on}" if in_force_regime.empty?

      in_force_regime.max_by(&:effective_from)
    end
  end
end
