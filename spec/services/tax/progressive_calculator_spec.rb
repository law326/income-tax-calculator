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

  it "rejects negative income" do
    expect { nz.calculate(-1) }.to raise_error(ArgumentError)
  end
end
