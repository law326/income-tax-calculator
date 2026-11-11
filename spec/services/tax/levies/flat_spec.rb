require "rails_helper"

RSpec.describe Tax::Levies::Flat do
  it "taxes all income at one rate" do
    charge = described_class.build("rate" => "0.2", "label" => "Levy").call(BigDecimal(500)).sole
    expect(charge).to have_attributes(label: "Levy", rate: BigDecimal("0.2"), taxable_amount: 500, amount: 100)
  end

  it "defaults the label" do
    expect(described_class.build("rate" => "0.2").call(BigDecimal(1)).sole.label).to eq "Flat tax"
  end
end
