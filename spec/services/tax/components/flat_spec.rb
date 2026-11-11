require "rails_helper"

RSpec.describe Tax::Components::Flat do
  it "taxes all income at one rate" do
    line = described_class.build("rate" => "0.2", "label" => "Levy").call(BigDecimal(500)).sole
    expect(line).to have_attributes(label: "Levy", rate: BigDecimal("0.2"), taxable: 500, tax: 100)
  end

  it "defaults the label" do
    expect(described_class.build("rate" => "0.2").call(BigDecimal(1)).sole.label).to eq "Flat tax"
  end
end
