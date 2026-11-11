require "rails_helper"

RSpec.describe Tax::RuleLoader do
  def load_bands(bands)
    file = Tempfile.new([ "xx", ".yml" ])
    file.write({ "name" => "X", "currency" => "XTS", "bands" => bands }.to_yaml)
    file.close
    described_class.new.call(file.path)
  end

  it "accepts ascending bands" do
    rule = load_bands([ { "up_to" => 10, "rate" => "0.1" }, { "up_to" => nil, "rate" => "0.2" } ])
    expect(rule.calculate(20).tax).to eq BigDecimal("3")
  end

  it "applies a boundary amount to the lower band only" do
    rule = load_bands([ { "up_to" => 10, "rate" => "0.1" }, { "up_to" => nil, "rate" => "0.2" } ])
    expect(rule.calculate(10).tax).to eq BigDecimal("1")
    expect(rule.calculate("10.5").tax).to eq BigDecimal("1.10")
  end

  it "rejects equal up_to values" do
    expect { load_bands([ { "up_to" => 10, "rate" => "0.1" }, { "up_to" => 10, "rate" => "0.2" } ]) }
      .to raise_error(Tax::RuleLoader::InvalidBands)
  end

  it "rejects descending up_to values" do
    expect { load_bands([ { "up_to" => 10, "rate" => "0.1" }, { "up_to" => 5, "rate" => "0.2" } ]) }
      .to raise_error(Tax::RuleLoader::InvalidBands)
  end

  it "rejects a band after an unbounded one" do
    expect { load_bands([ { "up_to" => nil, "rate" => "0.1" }, { "up_to" => 10, "rate" => "0.2" } ]) }
      .to raise_error(Tax::RuleLoader::InvalidBands)
  end
end
