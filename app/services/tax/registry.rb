module Tax
  # All regimes, loaded from one YAML file per country (file name = country code).
  # A country has one regime per dated version, e.g. NZ has one from 2024-04-01 and another from 2025-04-01.
  class Registry
    class UnknownCountry < StandardError; end
    class NoRegimeInForce < StandardError; end
    class DuplicateVersion < StandardError; end

    LEVY_TYPES = { "graduated" => Levies::Graduated, "flat" => Levies::Flat }.freeze

    def self.default = @default ||= new

    def initialize(dir: Rails.root.join("config/tax_rules"))
      @regimes = Dir[File.join(dir, "*.yml")].sort.flat_map { load_file(_1) }
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

    private

    def load_file(path)
      country = YAML.safe_load_file(path, permitted_classes: [ Date ])
      code = File.basename(path, ".yml").upcase
      versions = country.fetch("versions")
      ensure_unique_dates!(code, versions)

      versions.map do |version|
        Regime.new(code:, name: country.fetch("name"), currency: country.fetch("currency"), symbol: country.fetch("symbol"),
                   effective_from: version.fetch("effective_from"),
                   levies: version.fetch("levies").map { build_levy(_1) })
      end
    end

    def ensure_unique_dates!(code, versions)
      dates = versions.map { _1.fetch("effective_from") }
      raise DuplicateVersion, "#{code} has duplicate effective_from dates" if dates.uniq.size != dates.size
    end

    def build_levy(config) = LEVY_TYPES.fetch(config.fetch("type")).build(config)
  end
end
