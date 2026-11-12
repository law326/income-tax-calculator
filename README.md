# Income Tax Calculator

Rails app that estimates annual personal income tax. Enter a country, an annual income and an income date. It shows the tax payable, net income, effective rate and a per-band breakdown.

Ships with New Zealand (2024-25 and 2025-26 rates) and United Kingdom rules. Rules are YAML data, so rates, bands and countries change without code changes.

## Requirements and setup

- Ruby 3.4.9 (see `.ruby-version`)
- Bundler
- No database or JavaScript build

```sh
bundle install
bin/rails server
```

Open http://localhost:3000.

## Tests and coverage

```sh
bundle exec rspec
```

SimpleCov runs with the suite and fails it below 100% line and branch coverage. The HTML report is written to `coverage/index.html`.

`bin/ci` runs RuboCop, bundler-audit, Brakeman and the specs.

## Approach

A `Regime` is a country's rules from a given date. It is the sum of its `levies`. Each levy turns an income into `Assessment::Charge` lines.

```
config/tax_rules/<code>.yml  ->  RegimeLoader  ->  Registry  ->  find(code, on:)  ->  Regime(levies)  ->  Assessment(charges)
```

| Class | Role |
|---|---|
| `RegimeLoader` | Reads one YAML file per country into regimes, one per dated version. |
| `Registry` | Looks regimes up. `find(code, on:)` picks the version in force on a date. |
| `Regime` | Parses income, runs its levies, returns an `Assessment`. |
| `Levies::Graduated` | Marginal bands, with `Levies::Band` as one band. |
| `Levies::Flat` | A single rate on all income. |
| `Assessment` | Gross and net income, tax payable, effective rate and `Charge` lines. |

### Adding or changing rules

Edit or add a file in `config/tax_rules/`. The file name, uppercased, is the country code.

```yaml
name: Example
currency: EXD
symbol: "$"
versions:                       # one entry per rate change; dates must be unique
  - effective_from: 2025-04-01
    levies:
      - type: graduated
        bands:                  # each band starts where the previous up_to ended
          - { up_to: 15600, rate: "0.105" }
          - { up_to: ~, rate: "0.39" }   # last band has no up_to
      - type: flat
        label: Levy
        rate: "0.0167"
```

A new tax structure is a new class under `app/services/tax/levies/` with `self.build(config)` and `call(income)`, plus an entry in `RegimeLoader::LEVY_TYPES` (or pass `levy_types:` to `RegimeLoader.new`).

### Key decisions and assumptions

- **Rules are data.** Rate changes are YAML edits and old versions stay in place, so past calculations stay reproducible.
- **Composition over inheritance.** A regime is a list of levies. A country mixes structures (for example bands plus a flat levy) without subclassing, and each levy is small and tested alone.
- **Versions by date.** The income date selects the rates in force. NZ's tax year (1 April to 31 March) falls out of the `effective_from` dates.
- **Band boundaries.** A band covers income above the previous `up_to`, up to and including its own. A boundary amount is taxed once, in the lower band. `up_to` values must ascend and only the last band may be unbounded. Bad files raise `Tax::InvalidRules` when first loaded.
- **Exact arithmetic.** `BigDecimal` throughout. Rates are quoted strings in YAML.
- **Rounding.** Gross income is rounded to cents on input. Each charge is rounded to cents, half up, and the total is the sum of the rounded charges. Displayed lines always add up to the total.
- **Input.** Annual income, non-negative and finite. Anything else gives a form error.
- **Test values.** The NZ 2025 cases are from the IRD brief. The 2024-25 and UK values are hand calculated, so verify them against official sources.

### Trade-offs

- **Simple model over completeness.** Only income tax bands and flat levies exist. Anything else needs a new levy class.
- **Per-charge rounding** keeps the display consistent, but could differ by a cent from rounding the grand total, if a jurisdiction requires that.
- **Date field instead of a tax-year picker.** A tax-year dropdown depends on the chosen country and needs JavaScript. A date is simpler and works for any country.
- **Rules load once, on first use.** YAML edits need a restart, in exchange for fast lookups and validation up front.
- **No database.** Nothing is stored. Rules live in the repo.
- **Plain ERB and minimal CSS.** No JavaScript, so no build step and easy to read.

## Future improvements

- UK personal allowance taper above £100,000.
- Other NZ items: ACC earner levy, tax codes, student loan, KiwiSaver.
- Tax-year picker, and monthly or fortnightly pay periods.
- Per-jurisdiction rounding rules (for example whole dollars).
- Validation of rates (0 to 1) and clearer errors for malformed YAML.
- Currency formatting by locale.
- JSON API endpoint for other tools.
- A system test of the form in a real browser.
