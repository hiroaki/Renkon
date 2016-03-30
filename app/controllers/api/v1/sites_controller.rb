class Api::V1::SitesController < ApplicationController
  def index
    @sites = Site.all
    render jbuilder: @sites
  end
  def channels
    @sites = Site.all
    render jbuilder: @sites
  end
  def articles
    @channel = Channel.find(params[:id])
    render jbuilder: @channel
  end
  def show
    @site = Site.find(params[:id])
    render jbuilder: @site
  end
end
