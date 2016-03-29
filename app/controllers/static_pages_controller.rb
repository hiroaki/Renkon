class StaticPagesController < ApplicationController
  def browser
    render :layout => false
  end
end
