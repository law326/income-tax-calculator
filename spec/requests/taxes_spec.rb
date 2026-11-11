require "rails_helper"

RSpec.describe "Taxes", type: :request do
  it "renders the form" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include "<form"
  end

  it "calculates tax" do
    post tax_path, params: { country: "NZ", income: "100000" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include "22,877.50"
  end

  it "rejects invalid income" do
    post tax_path, params: { country: "NZ", income: "-5" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include "income must be a non-negative number"
  end

  it "rejects unknown country" do
    post tax_path, params: { country: "ZZ", income: "5" }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
