require "rails_helper"

RSpec.describe Tax::Registry do
  it "loads regimes with mixed levies from a custom directory" do
    registry = described_class.new(dir: Rails.root.join("spec/fixtures/tax_rules"))
    regime = registry.find("xx")
    expect(registry.all.map(&:code)).to eq [ "XX" ]
    expect(regime.currency).to eq "XTS"
    expect(regime.assess(2000).tax_payable).to eq BigDecimal("220")
  end

  it "includes NZ by default" do
    expect(described_class.default.all.map(&:code)).to include "NZ"
  end

  it "raises for unknown country" do
    expect { described_class.default.find("ZZ") }.to raise_error(Tax::Registry::UnknownCountry)
  end

  it "raises for unknown levy type" do
    Dir.mktmpdir do |dir|
      File.write("#{dir}/yy.yml", { "name" => "Y", "currency" => "Y", "levies" => [ { "type" => "nope" } ] }.to_yaml)
      expect { described_class.new(dir:) }.to raise_error(KeyError, /nope/)
    end
  end
end
