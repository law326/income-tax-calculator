require "rails_helper"

RSpec.describe Tax::Registry do
  it "loads rules with mixed components from a custom directory" do
    registry = described_class.new(dir: Rails.root.join("spec/fixtures/tax_rules"))
    rule = registry.find("xx")
    expect(registry.all.map(&:code)).to eq [ "XX" ]
    expect(rule.currency).to eq "XTS"
    expect(rule.calculate(2000).tax).to eq BigDecimal("220")
  end

  it "includes NZ by default" do
    expect(described_class.default.all.map(&:code)).to include "NZ"
  end

  it "raises for unknown country" do
    expect { described_class.default.find("ZZ") }.to raise_error(Tax::Registry::UnknownCountry)
  end

  it "raises for unknown component type" do
    Dir.mktmpdir do |dir|
      File.write("#{dir}/yy.yml", { "name" => "Y", "currency" => "Y", "components" => [ { "type" => "nope" } ] }.to_yaml)
      expect { described_class.new(dir:) }.to raise_error(KeyError)
    end
  end
end
