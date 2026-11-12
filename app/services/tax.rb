module Tax
  class Error < StandardError; end
  class InvalidIncome < Error; end
  class UnknownCountry < Error; end
  class NoRegimeInForce < Error; end

  # Raised for a faulty rules file
  class InvalidRules < StandardError; end
end
