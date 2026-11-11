class TaxesController < ApplicationController
  def new
    @regimes = registry.all
  end

  def create
    @regimes = registry.all
    @regime = registry.find(params[:country])
    @assessment = @regime.assess(params[:income])
    render :new
  rescue ArgumentError, Tax::Registry::UnknownCountry => e
    @error = e.message
    render :new, status: :unprocessable_content
  end

  private

  def registry = Tax::Registry.default
end
