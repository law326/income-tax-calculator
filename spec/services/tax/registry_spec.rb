require "rails_helper"

RSpec.describe Tax::Registry do
  def regime(code, from, rate: "0.5")
    Tax::Regime.new(code:, name: code, currency: code, symbol: "$", effective_from: from,
                    levies: [ Tax::Levies::Flat.new(rate: BigDecimal(rate), label: "Flat") ])
  end

  let(:registry) do
    described_class.new([ regime("XX", Date.new(2010, 1, 1), rate: "0.5"), regime("XX", Date.new(2020, 1, 1), rate: "0.2"),
                          regime("YY", Date.new(2015, 1, 1)) ])
  end

  describe "#find" do
    it "picks the latest version in force on the date" do
      expect(registry.find("xx", on: Date.new(2020, 1, 1)).effective_from).to eq Date.new(2020, 1, 1)
      expect(registry.find("xx", on: Date.new(2019, 12, 31)).effective_from).to eq Date.new(2010, 1, 1)
      expect(registry.find("xx", on: Date.new(2015, 1, 1)).assess(1000).tax_payable).to eq BigDecimal("500")
    end

    it "defaults to today" do
      expect(registry.find("XX").effective_from).to eq Date.new(2020, 1, 1)
    end

    it "raises before the first version" do
      expect { registry.find("XX", on: Date.new(2009, 12, 31)) }.to raise_error(described_class::NoRegimeInForce)
    end

    it "raises for unknown country" do
      expect { registry.find("ZZ") }.to raise_error(described_class::UnknownCountry)
    end
  end

  describe "#all" do
    it "lists the newest regime per country" do
      expect(registry.all.map { [ _1.code, _1.effective_from ] })
        .to eq [ [ "XX", Date.new(2020, 1, 1) ], [ "YY", Date.new(2015, 1, 1) ] ]
    end
  end

  describe ".default" do
    let(:default) { described_class.default }

    it "includes NZ and UK" do
      expect(default.all.map(&:code)).to include "NZ", "UK"
    end

    it "switches NZ rates on 2025-04-01" do
      expect(default.find("NZ", on: Date.new(2025, 4, 1)).effective_from).to eq Date.new(2025, 4, 1)
      expect(default.find("NZ", on: Date.new(2025, 3, 31)).effective_from).to eq Date.new(2024, 4, 1)
    end

    { 10_000 => "0", 50_000 => "7486.00", 100_000 => "27432.00", 150_000 => "48675.00" }.each do |income, tax|
      it "taxes UK income #{income} at #{tax}" do
        expect(default.find("UK", on: Date.new(2026, 4, 6)).assess(income).tax_payable).to eq BigDecimal(tax)
      end
    end

    it "has no UK rates before 2026-04-06" do
      expect { default.find("UK", on: Date.new(2026, 4, 5)) }.to raise_error(described_class::NoRegimeInForce)
    end
  end
end
