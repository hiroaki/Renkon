class Api::V1::SitesController < ApplicationController
  def index
    @sites = Site.all
    render jbuilder: @sites
  end
  def show
    @site = Site.find(params[:id])
    render jbuilder: @site
  end
end
