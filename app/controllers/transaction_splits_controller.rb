# frozen_string_literal: true

class TransactionSplitsController < ApplicationController
  def create
    @transaction = Transaction.find(params[:transaction_id])
    @split = @transaction.transaction_splits.new(split_params)

    if @split.save
      redirect_to edit_transaction_path(@transaction), notice: "Split added."
    else
      redirect_to edit_transaction_path(@transaction), alert: "Failed to add split."
    end
  end

  def destroy
    split = TransactionSplit.find(params[:id])
    transaction = split.transaction_record
    split.destroy
    redirect_to edit_transaction_path(transaction), notice: "Split removed."
  end

  private

  def split_params
    params.require(:transaction_split).permit(:budget_item_id, :amount)
  end
end
