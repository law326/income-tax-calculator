module Tax
  # Rules loaded from one YAML file per country (file name = country code).
  class Registry
    class UnknownCountry < StandardError; end

    COMPONENTS = { "progressive" => Components::Progressive, "flat" => Components::Flat }.freeze

    def self.default = @default ||= new

    def initialize(dir: Rails.root.join("config/tax_rules"))
      @rules = Dir[File.join(dir, "*.yml")].sort.map { load_rule(_1) }.index_by(&:code)
    end

    def all = @rules.values

    def find(code)
      @rules.fetch(code.to_s.upcase) { raise UnknownCountry, "unknown country: #{code}" }
    end

    private

    def load_rule(path)
      data = YAML.safe_load_file(path)
      components = data.fetch("components").map { COMPONENTS.fetch(_1.fetch("type")).build(_1) }
      Rule.new(code: File.basename(path, ".yml").upcase, name: data.fetch("name"),
               currency: data.fetch("currency"), components:)
    end
  end
end
