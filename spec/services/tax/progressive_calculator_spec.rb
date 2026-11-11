require "rails_helper"

RSpec.describe Tax::ProgressiveCalculator do
  let(:nz) { Tax::Registry.default.find("NZ") }

  {
    0 => "0", 10_000 => "1050.00", 15_600 => "1638.00", 35_000 => "5033.00",
    100_000 => "22877.50", 220_000 => "64877.50"
  }.each do |income, tax|
    it "taxes NZ income #{income} at #{tax}" do
      expect(nz.calculate(income).tax).to eq BigDecimal(tax)
    end
  end

  it "derives net and effective rate" do
    result = nz.calculate(10_000)
    expect(result.net).to eq BigDecimal("8950")
    expect(result.effective_rate).to eq BigDecimal("0.105")
  end

  it "has zero effective rate for zero income" do
    expect(nz.calculate(0).effective_rate).to eq 0
  end

  it "rounds to cents" do
    expect(nz.calculate("1.005").tax).to eq BigDecimal("0.11")
  end

  it "taxes fractional income across a band boundary" do
    expect(nz.calculate("15600.50").tax).to eq BigDecimal("1638.09")
  end

  it "ignores surrounding whitespace" do
    expect(nz.calculate(" 10000 ").tax).to eq BigDecimal("1050")
  end

  [ -1, "abc", "", nil, "NaN", "Infinity", "1,000" ].each do |bad|
    it "rejects #{bad.inspect}" do
      expect { nz.calculate(bad) }.to raise_error(ArgumentError, "income must be a non-negative number")
    end
  end
end
