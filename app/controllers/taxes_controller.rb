class TaxesController < ApplicationController
  def new
    @regimes = registry.all
  end

  def create
    @regimes = registry.all
    @regime = registry.find(params[:country], on: income_date)
    @assessment = @regime.assess(params[:income])
    render :new
  rescue Tax::Error, Date::Error => e
    @error = e.message
    render :new, status: :unprocessable_content
  end

  private

  def registry = Tax::Registry.default

  def income_date = params[:date].presence ? Date.iso8601(params[:date]) : Date.current
end
