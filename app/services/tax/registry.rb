module Tax
  # Regimes loaded from one YAML file per country (file name = country code).
  class Registry
    class UnknownCountry < StandardError; end

    LEVIES = { "graduated" => Levies::Graduated, "flat" => Levies::Flat }.freeze

    def self.default = @default ||= new

    def initialize(dir: Rails.root.join("config/tax_rules"))
      @regimes = Dir[File.join(dir, "*.yml")].sort.map { load_regime(_1) }.index_by(&:code)
    end

    def all = @regimes.values

    def find(code)
      @regimes.fetch(code.to_s.upcase) { raise UnknownCountry, "unknown country: #{code}" }
    end

    private

    def load_regime(path)
      data = YAML.safe_load_file(path)
      levies = data.fetch("levies").map { LEVIES.fetch(_1.fetch("type")).build(_1) }
      Regime.new(code: File.basename(path, ".yml").upcase, name: data.fetch("name"),
                 currency: data.fetch("currency"), levies:)
    end
  end
end
