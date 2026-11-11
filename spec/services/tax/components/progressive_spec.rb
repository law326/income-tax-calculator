require "rails_helper"

RSpec.describe Tax::Components::Progressive do
  def build(*ups)
    described_class.build("bands" => ups.map { { "up_to" => _1, "rate" => "0.1" } })
  end

  it "returns a labelled line per band" do
    lines = build(10_000, nil).call(BigDecimal(12_000))
    expect(lines.map(&:label)).to eq [ "0 - 10,000", "10,000 - and over" ]
    expect(lines.map(&:taxable)).to eq [ BigDecimal(10_000), BigDecimal(2000) ]
  end

  it "counts a boundary amount in the lower band only" do
    lines = build(10, nil).call(BigDecimal(10))
    expect(lines.map(&:taxable)).to eq [ BigDecimal(10), 0 ]
  end

  it("accepts ascending bands") { expect { build(10, 20, nil) }.not_to raise_error }
  it("rejects equal up_to values") { expect { build(10, 10, nil) }.to raise_error(described_class::InvalidBands) }
  it("rejects descending up_to values") { expect { build(10, 5, nil) }.to raise_error(described_class::InvalidBands) }
  it("rejects a band after an unbounded one") { expect { build(nil, 10) }.to raise_error(described_class::InvalidBands) }
end
