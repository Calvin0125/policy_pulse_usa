# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HomeController', type: :request do
  describe 'GET /home/index' do
    context 'when path is not equal to /' do
      it 'redirects to /' do
        get '/bills'
        expect(response).to redirect_to('/')
      end
    end

    context 'when there is no path' do
      it 'does not redirect' do
        get ''
        expect(response).to have_http_status(:success) # or any other expected behavior
      end
    end

    context 'when path is /' do
      it 'does not redirect' do
        get '/'
        expect(response).to have_http_status(:success) # or any other expected behavior
      end
    end
  end
end
