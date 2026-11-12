require "rails_helper"

RSpec.describe "taxes/new", type: :view do
  let(:regime) do
    Tax::Regime.new(code: "XX", name: "Testland", currency: "XTS", symbol: "X$", effective_from: Date.new(2025, 4, 1),
                    levies: [ Tax::Levies::Flat.new(rate: BigDecimal("0.10549"), label: "Levy") ])
  end

  before do
    assign(:regimes, [ regime ])
    assign(:regime, regime)
    assign(:assessment, regime.assess("1000"))
    render
  end

  it "shows rates to 4 decimals of percent" do
    expect(rendered).to include "10.549%"
  end

  it "shows the effective rate to 2 decimals" do
    expect(rendered).to include "<dt>Effective rate</dt><dd>10.55%</dd>"
  end

  it "uses the regime symbol for every amount" do
    expect(rendered).to include "X$894.51", "X$1,000.00", "X$105.49"
    expect(rendered).not_to match(/(?<!X)\$\d/)
  end
end
