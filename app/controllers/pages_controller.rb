# frozen_string_literal: true

class PagesController < ApplicationController
  def dashboard
    render Views::Pages::DashboardView.new
  end
end
