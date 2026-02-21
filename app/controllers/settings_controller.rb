# frozen_string_literal: true

class SettingsController < ApplicationController
  def index
    @current_page = "Settings"
    @user = Current.user
    @categories = BudgetCategory.ordered
    render Views::Settings::IndexView.new(user: @user, categories: @categories)
  end

  def update_profile
    if Current.user.update(profile_params)
      redirect_to settings_path, notice: "Profile updated."
    else
      @current_page = "Settings"
      @categories = BudgetCategory.ordered
      render Views::Settings::IndexView.new(user: Current.user, categories: @categories), status: :unprocessable_entity
    end
  end

  def update_category
    category = BudgetCategory.find(params[:id])
    if category.update(category_params)
      redirect_to settings_path, notice: "Category updated."
    else
      redirect_to settings_path, alert: "Failed to update category."
    end
  end

  def create_category
    category = BudgetCategory.new(category_params)
    category.position = BudgetCategory.maximum(:position).to_i + 1
    if category.save
      redirect_to settings_path, notice: "Category added."
    else
      redirect_to settings_path, alert: "Failed to add category."
    end
  end

  def destroy_category
    BudgetCategory.find(params[:id]).destroy
    redirect_to settings_path, notice: "Category removed."
  end

  private

  def profile_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def category_params
    params.require(:budget_category).permit(:name, :icon, :color)
  end
end
