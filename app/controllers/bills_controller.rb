class BillsController < ApplicationController
  BILLS_PER_PAGE = 10

  def index
    bills = Bill.order(updated_at: :desc)
                .paginate(page: bill_params[:page], per_page: BILLS_PER_PAGE)

    render json: { bills: bills }
  end

  private

  def bill_params
    params.permit(:page)
  end
end