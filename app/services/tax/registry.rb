module Tax
  # Country rule sets, one YAML file per country in the rules directory.
  class Registry
    class UnknownCountry < StandardError; end

    def initialize(dir: Rails.root.join("config/tax_rules"), loader: RuleLoader.new)
      @rules = Dir[File.join(dir, "*.yml")].sort.map { loader.call(_1) }.index_by(&:code)
    end

    def all = @rules.values

    def find(code)
      @rules.fetch(code.to_s.upcase) { raise UnknownCountry, "unknown country: #{code}" }
    end

    def self.default = @default ||= new
  end
end
