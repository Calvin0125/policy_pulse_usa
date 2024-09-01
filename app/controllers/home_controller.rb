# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    return unless params[:path] && params[:path] != '/'

    redirect_to '/'
  end
end
