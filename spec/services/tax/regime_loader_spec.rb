require "rails_helper"

RSpec.describe Tax::RegimeLoader do
  let(:fixtures) { Rails.root.join("spec/fixtures/tax_rules") }

  def write_country(dir, versions)
    File.write("#{dir}/yy.yml", { "name" => "Y", "currency" => "Y", "symbol" => "Y", "versions" => versions }.to_yaml)
  end

  it "builds a regime per dated version with mixed levies" do
    regimes = described_class.new(dir: fixtures).call
    expect(regimes.map(&:code)).to eq %w[XX XX]
    expect(regimes.map(&:effective_from)).to eq [ Date.new(2020, 1, 1), Date.new(2010, 1, 1) ]
    expect(regimes.first).to have_attributes(name: "Testland", currency: "XTS", symbol: "X$")
    expect(regimes.first.assess(2000).tax_payable).to eq BigDecimal("220")
  end

  it "loads the default rules" do
    expect(described_class.new.call.map(&:code).uniq).to include "NZ", "UK"
  end

  it "rejects duplicate effective dates" do
    Dir.mktmpdir do |dir|
      write_country(dir, [ { "effective_from" => Date.new(2020, 1, 1), "levies" => [] }, { "effective_from" => Date.new(2020, 1, 1), "levies" => [] } ])
      expect { described_class.new(dir:).call }.to raise_error(Tax::InvalidRules)
    end
  end

  it "raises for unknown levy type" do
    Dir.mktmpdir do |dir|
      write_country(dir, [ { "effective_from" => Date.new(2020, 1, 1), "levies" => [ { "type" => "nope" } ] } ])
      expect { described_class.new(dir:).call }.to raise_error(KeyError, /nope/)
    end
  end

  it "builds levies from injected levy types" do
    custom = Class.new do
      def self.build(config) = new
      def call(_income) = []
    end
    Dir.mktmpdir do |dir|
      write_country(dir, [ { "effective_from" => Date.new(2020, 1, 1), "levies" => [ { "type" => "custom" } ] } ])
      regime = described_class.new(dir:, levy_types: { "custom" => custom }).call.sole
      expect(regime.assess(100).charges).to be_empty
    end
  end
end
