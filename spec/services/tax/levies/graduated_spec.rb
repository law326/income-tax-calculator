require "rails_helper"

RSpec.describe Tax::Levies::Graduated do
  def build(*ups)
    described_class.build("bands" => ups.map { { "up_to" => _1, "rate" => "0.1" } })
  end

  def band(floor, ceiling) = Tax::Levies::Band.new(floor: BigDecimal(floor), ceiling: ceiling && BigDecimal(ceiling), rate: BigDecimal("0.1"))

  it "returns a labelled charge per band" do
    charges = build(10_000, nil).call(BigDecimal(12_000))
    expect(charges.map(&:label)).to eq [ "0 - 10,000", "10,000 - and over" ]
    expect(charges.map(&:taxable_amount)).to eq [ BigDecimal(10_000), BigDecimal(2000) ]
    expect(charges.map(&:amount)).to eq [ BigDecimal(1000), BigDecimal(200) ]
  end

  it "counts a boundary amount in the lower band only" do
    charges = build(10, nil).call(BigDecimal(10))
    expect(charges.map(&:taxable_amount)).to eq [ BigDecimal(10), 0 ]
  end

  describe "validation" do
    it("accepts ascending bands") { expect { build(10, 20, nil) }.not_to raise_error }
    it("rejects equal up_to values") { expect { build(10, 10, nil) }.to raise_error(Tax::InvalidRules) }
    it("rejects descending up_to values") { expect { build(10, 5, nil) }.to raise_error(Tax::InvalidRules) }
    it("rejects a band after an unbounded one") { expect { build(nil, 10) }.to raise_error(Tax::InvalidRules) }

    it "rejects a gap between hand-built bands" do
      expect { described_class.new([ band(0, 10), band(11, nil) ]) }.to raise_error(Tax::InvalidRules, /start where/)
    end

    it "rejects an overlap between hand-built bands" do
      expect { described_class.new([ band(0, 10), band(5, nil) ]) }.to raise_error(Tax::InvalidRules)
    end
  end
end
