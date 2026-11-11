class TaxesController < ApplicationController
  def new
    @rules = registry.all
  end

  def create
    @rules = registry.all
    @rule = registry.find(params[:country])
    @result = @rule.calculate(params[:income])
    render :new
  rescue ArgumentError, Tax::Registry::UnknownCountry => e
    @error = e.message
    render :new, status: :unprocessable_content
  end

  private

  def registry = Tax::Registry.default
end
