# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    if params[:path] && params[:path] != '/'
      redirect_to '/'
    end
  end
end
