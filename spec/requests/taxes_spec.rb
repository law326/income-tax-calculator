require "rails_helper"

RSpec.describe "Taxes", type: :request do
  it "renders the form" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include "<form", 'type="date"'
  end

  it "calculates tax using today's rates by default" do
    post tax_path, params: { country: "NZ", income: "100000" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include "$22,877.50"
  end

  it "uses the regime currency symbol" do
    post tax_path, params: { country: "UK", income: "100000" }
    expect(response.body).to include "£27,432.00"
  end

  it "uses the rates in force on the income date" do
    post tax_path, params: { country: "NZ", income: "15600", date: "2025-03-31" }
    expect(response.body).to include "1,675.12", "12.82%"
  end

  it "rejects invalid income" do
    post tax_path, params: { country: "NZ", income: "-5" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include "income must be a non-negative number"
  end

  it "rejects an invalid date" do
    post tax_path, params: { country: "NZ", income: "5", date: "nope" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects a date before any rates exist" do
    post tax_path, params: { country: "NZ", income: "5", date: "2000-01-01" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include "no NZ tax rates in force"
  end

  it "rejects unknown country" do
    post tax_path, params: { country: "ZZ", income: "5" }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
