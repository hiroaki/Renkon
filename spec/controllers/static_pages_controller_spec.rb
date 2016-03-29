require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do

  describe "GET #browser" do
    it "returns http success" do
      get :browser
      expect(response).to have_http_status(:success)
    end
  end

end
