# frozen_string_literal: true

class SavingsGoalsController < ApplicationController
  before_action :set_goal, only: [ :show, :edit, :update, :destroy ]

  def index
    @current_page = "Savings & Goals"
    @goals = SavingsGoal.by_priority
    render Views::SavingsGoals::IndexView.new(goals: @goals)
  end

  def show
    @current_page = "Savings & Goals"
    redirect_to savings_goals_path
  end

  def new
    @current_page = "Savings & Goals"
    render Views::SavingsGoals::FormView.new(goal: SavingsGoal.new)
  end

  def create
    @current_page = "Savings & Goals"
    @goal = SavingsGoal.new(goal_params)
    if @goal.save
      redirect_to savings_goals_path, notice: "Savings goal created."
    else
      render Views::SavingsGoals::FormView.new(goal: @goal), status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "Savings & Goals"
    render Views::SavingsGoals::FormView.new(goal: @goal)
  end

  def update
    @current_page = "Savings & Goals"
    if @goal.update(goal_params)
      redirect_to savings_goals_path, notice: "Savings goal updated."
    else
      render Views::SavingsGoals::FormView.new(goal: @goal), status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to savings_goals_path, notice: "Savings goal deleted."
  end

  private

  def set_goal
    @goal = SavingsGoal.find(params[:id])
  end

  def goal_params
    params.require(:savings_goal).permit(:name, :target_amount, :current_amount, :target_date, :category, :priority)
  end
end
