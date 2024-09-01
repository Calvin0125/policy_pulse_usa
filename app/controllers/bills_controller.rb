# frozen_string_literal: true

class BillsController < ApplicationController
  BILLS_PER_PAGE = 5

  def index
    bills = Bill.order(status_last_updated: :desc)
                .paginate(page: bill_params[:page], per_page: BILLS_PER_PAGE)
                .map(&:formatted_bill)

    render json: { bills: }
  end

  private

  def bill_params
    params.permit(:page)
  end
end
