module Tax
  # Raised for what the caller asked for: safe to show to users.
  class Error < StandardError; end
  class InvalidIncome < Error; end
  class UnknownCountry < Error; end
  class NoRegimeInForce < Error; end

  # Raised for a faulty rules file: a bug to fix, not a user error.
  class InvalidRules < StandardError; end
end
