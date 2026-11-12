require "rails_helper"

RSpec.describe Tax::Levies::Band do
  def make_band(floor, ceiling) = described_class.new(floor: BigDecimal(floor), ceiling: ceiling && BigDecimal(ceiling.to_s), rate: BigDecimal("0.1"))

  describe "#taxable_amount" do
    let(:band) { make_band(10, 20) }

    it "is zero below the band" do
      expect(band.taxable_amount(BigDecimal(5))).to eq 0
    end

    it "counts only income within the band" do
      expect(band.taxable_amount(BigDecimal(15))).to eq 5
    end

    it "caps at the ceiling, which belongs to this band" do
      expect(band.taxable_amount(BigDecimal(20))).to eq 10
      expect(band.taxable_amount(BigDecimal(99))).to eq 10
    end

    it "has no cap when unbounded" do
      expect(make_band(10, nil).taxable_amount(BigDecimal(99))).to eq 89
    end
  end

  describe "#label" do
    it("shows a delimited range") { expect(make_band(0, 10_000).label).to eq "0 - 10,000" }
    it("shows an unbounded band") { expect(make_band(10_000, nil).label).to eq "10,000 - and over" }
    it("keeps fractional boundaries") { expect(make_band(0, 1000.5).label).to eq "0 - 1,000.5" }
  end

  describe "validation" do
    it("rejects a ceiling equal to the floor") { expect { make_band(10, 10) }.to raise_error(Tax::Levies::Band::InvalidBands) }
    it("rejects a ceiling below the floor") { expect { make_band(10, 5) }.to raise_error(Tax::Levies::Band::InvalidBands) }
    it("rejects a missing floor") { expect { described_class.new(floor: nil, ceiling: BigDecimal(5), rate: 0) }.to raise_error(Tax::Levies::Band::InvalidBands) }
  end
end
