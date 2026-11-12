module Tax
  # Reads one YAML file per country (file name = country code) into regimes, one per dated version.
  class RegimeLoader
    LEVY_TYPES = { "graduated" => Levies::Graduated, "flat" => Levies::Flat }.freeze

    def initialize(dir: Rails.root.join("config/tax_rules"), levy_types: LEVY_TYPES)
      @dir = dir
      @levy_types = levy_types
    end

    def call
      Dir[File.join(@dir, "*.yml")].sort.flat_map { load_file(_1) }
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
      raise InvalidRules, "#{code} has duplicate effective_from dates" if dates.uniq.size != dates.size
    end

    def build_levy(config) = @levy_types.fetch(config.fetch("type")).build(config)
  end
end
