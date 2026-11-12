require "rails_helper"

RSpec.describe Tax::Registry do
  let(:registry) { described_class.new(dir: Rails.root.join("spec/fixtures/tax_rules")) }

  def write_country(dir, versions)
    File.write("#{dir}/yy.yml", { "name" => "Y", "currency" => "Y", "symbol" => "Y", "versions" => versions }.to_yaml)
  end

  it "loads regimes with mixed levies from a custom directory" do
    regime = registry.find("xx")
    expect(registry.all.map(&:code)).to eq [ "XX" ]
    expect(regime.currency).to eq "XTS"
    expect(regime.symbol).to eq "X$"
    expect(regime.assess(2000).tax_payable).to eq BigDecimal("220")
  end

  describe "versions" do
    it "picks the latest version in force on the date" do
      expect(registry.find("xx", on: Date.new(2020, 1, 1)).effective_from).to eq Date.new(2020, 1, 1)
      expect(registry.find("xx", on: Date.new(2019, 12, 31)).effective_from).to eq Date.new(2010, 1, 1)
      expect(registry.find("xx", on: Date.new(2015, 1, 1)).assess(1000).tax_payable).to eq BigDecimal("500")
    end

    it "lists the latest version per country" do
      expect(registry.all.map(&:effective_from)).to eq [ Date.new(2020, 1, 1) ]
    end

    it "raises before the first version" do
      expect { registry.find("xx", on: Date.new(2009, 12, 31)) }.to raise_error(described_class::NoRegimeInForce)
    end

    it "rejects duplicate effective dates" do
      Dir.mktmpdir do |dir|
        write_country(dir, [ { "effective_from" => Date.new(2020, 1, 1), "levies" => [] }, { "effective_from" => Date.new(2020, 1, 1), "levies" => [] } ])
        expect { described_class.new(dir:) }.to raise_error(described_class::DuplicateVersion)
      end
    end
  end

  describe "defaults" do
    it "includes NZ and UK" do
      expect(described_class.default.all.map(&:code)).to include "NZ", "UK"
    end

    it "uses the current NZ rates for 2025-04-01 onwards" do
      expect(described_class.default.find("NZ", on: Date.new(2025, 4, 1)).effective_from).to eq Date.new(2025, 4, 1)
      expect(described_class.default.find("NZ", on: Date.new(2025, 3, 31)).effective_from).to eq Date.new(2024, 4, 1)
    end

    {
      10_000 => "0", 50_000 => "7486.00", 100_000 => "27432.00", 150_000 => "48675.00"
    }.each do |income, tax|
      it "taxes UK income #{income} at #{tax}" do
        uk = described_class.default.find("UK", on: Date.new(2026, 4, 6))
        expect(uk.assess(income).tax_payable).to eq BigDecimal(tax)
      end
    end

    it "has no UK rates before 2026-04-06" do
      expect { described_class.default.find("UK", on: Date.new(2026, 4, 5)) }.to raise_error(described_class::NoRegimeInForce)
    end
  end

  it "raises for unknown country" do
    expect { described_class.default.find("ZZ") }.to raise_error(described_class::UnknownCountry)
  end

  it "raises for unknown levy type" do
    Dir.mktmpdir do |dir|
      write_country(dir, [ { "effective_from" => Date.new(2020, 1, 1), "levies" => [ { "type" => "nope" } ] } ])
      expect { described_class.new(dir:) }.to raise_error(KeyError, /nope/)
    end
  end
end
