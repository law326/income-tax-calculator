require "rails_helper"

RSpec.describe Tax::Regime do
  let(:nz) { Tax::Registry.default.find("NZ", on: Date.new(2025, 4, 1)) }

  {
    0 => "0", 10_000 => "1050.00", 15_600 => "1638.00", 35_000 => "5033.00",
    100_000 => "22877.50", 220_000 => "64877.50"
  }.each do |income, tax|
    it "taxes NZ income #{income} at #{tax}" do
      expect(nz.assess(income).tax_payable).to eq BigDecimal(tax)
    end
  end

  it "derives net and effective rate" do
    assessment = nz.assess(10_000)
    expect(assessment.net_income).to eq BigDecimal("8950")
    expect(assessment.effective_rate).to eq BigDecimal("0.105")
  end

  it "has zero effective rate for zero income" do
    expect(nz.assess(0).effective_rate).to eq 0
  end

  it "rounds to cents" do
    expect(nz.assess("1.005").tax_payable).to eq BigDecimal("0.11")
  end

  it "taxes fractional income across a band boundary" do
    expect(nz.assess("15600.50").tax_payable).to eq BigDecimal("1638.09")
  end

  it "ignores surrounding whitespace" do
    expect(nz.assess(" 10000 ").tax_payable).to eq BigDecimal("1050")
  end

  [ -1, "abc", "", nil, "NaN", "Infinity", "1,000" ].each do |bad|
    it "rejects #{bad.inspect}" do
      expect { nz.assess(bad) }.to raise_error(ArgumentError, "income must be a non-negative number")
    end
  end

  describe "NZ 2024-25 rates" do
    let(:nz24) { Tax::Registry.default.find("NZ", on: Date.new(2025, 3, 31)) }

    { 14_000 => "1470.00", 15_600 => "1675.12", 50_000 => "7777.92", 100_000 => "23222.51" }.each do |income, tax|
      it "taxes income #{income} at #{tax}" do
        expect(nz24.assess(income).tax_payable).to eq BigDecimal(tax)
      end
    end
  end

  describe "levies" do
    let(:regime) do
      described_class.new(code: "XX", name: "X", currency: "XTS", effective_from: Date.new(2020, 1, 1), levies: [
        Tax::Levies::Flat.new(rate: BigDecimal("0.1"), label: "A"),
        Tax::Levies::Flat.new(rate: BigDecimal("0.05"), label: "B")
      ])
    end

    it "sums levy amounts and keeps one charge each" do
      assessment = regime.assess(1000)
      expect(assessment.tax_payable).to eq BigDecimal("150")
      expect(assessment.charges.map(&:label)).to eq %w[A B]
    end
  end
end
