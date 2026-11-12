require "rails_helper"

RSpec.describe Tax::Levies::Graduated do
  def build(*ups)
    described_class.build("bands" => ups.map { { "up_to" => _1, "rate" => "0.1" } })
  end

  it "returns a labelled charge per band" do
    charges = build(10_000, nil).call(BigDecimal(12_000))
    expect(charges.map(&:label)).to eq [ "0 - 10,000", "10,000 - and over" ]
    expect(charges.map(&:taxable_amount)).to eq [ BigDecimal(10_000), BigDecimal(2000) ]
  end

  it "labels fractional boundaries without truncating" do
    expect(build(1000.5, nil).call(BigDecimal(1)).map(&:label)).to eq [ "0 - 1,000.5", "1,000.5 - and over" ]
  end

  it "counts a boundary amount in the lower band only" do
    charges = build(10, nil).call(BigDecimal(10))
    expect(charges.map(&:taxable_amount)).to eq [ BigDecimal(10), 0 ]
  end

  it("accepts ascending bands") { expect { build(10, 20, nil) }.not_to raise_error }
  it("rejects equal up_to values") { expect { build(10, 10, nil) }.to raise_error(described_class::InvalidBands) }
  it("rejects descending up_to values") { expect { build(10, 5, nil) }.to raise_error(described_class::InvalidBands) }
  it("rejects a band after an unbounded one") { expect { build(nil, 10) }.to raise_error(described_class::InvalidBands) }
end
