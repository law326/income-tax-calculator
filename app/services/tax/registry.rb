module Tax
  # Regimes loaded from one YAML file per country (file name = country code), each with dated versions.
  class Registry
    class UnknownCountry < StandardError; end
    class NoRegimeInForce < StandardError; end
    class DuplicateVersion < StandardError; end

    LEVIES = { "graduated" => Levies::Graduated, "flat" => Levies::Flat }.freeze

    def self.default = @default ||= new

    def initialize(dir: Rails.root.join("config/tax_rules"))
      @regimes = Dir[File.join(dir, "*.yml")].sort.flat_map { load_regimes(_1) }
                                             .group_by(&:code).transform_values { |v| v.sort_by(&:effective_from).reverse }
    end

    # Latest regime per country.
    def all = @regimes.values.map(&:first)

    def find(code, on: Date.current)
      versions = @regimes.fetch(code.to_s.upcase) { raise UnknownCountry, "unknown country: #{code}" }
      versions.find { _1.effective_from <= on } || raise(NoRegimeInForce, "no #{code.to_s.upcase} tax rates in force on #{on}")
    end

    private

    def load_regimes(path)
      data = YAML.safe_load_file(path, permitted_classes: [ Date ])
      code = File.basename(path, ".yml").upcase
      dates = data.fetch("versions").map { _1.fetch("effective_from") }
      raise DuplicateVersion, "#{code} has duplicate effective_from dates" unless dates.uniq.size == dates.size

      data.fetch("versions").map do |version|
        levies = version.fetch("levies").map { LEVIES.fetch(_1.fetch("type")).build(_1) }
        Regime.new(code:, name: data.fetch("name"), currency: data.fetch("currency"), symbol: data.fetch("symbol"),
                   effective_from: version.fetch("effective_from"), levies:)
      end
    end
  end
end
