class SitesController < ApplicationController
  def index
    @sites = Site.all
  end

  def show
    @site = Site.find(params[:id])
  end

  def new
    @site = Site.new
  end

  def edit
    @site = Site.find(params[:id])
  end

  def update
    @site = Site.find(params[:id])
    if @site.update(site_params)
      redirect_to @site, notice: "Updated"
    else
      render :edit, alert: "Canceled"
    end
  end

  def create
    @site = Site.new(site_params)
    if @site.save
      redirect_to @site, notice: "Created"
    else
      render :new, alert: "Canceled"
    end
  end

  private
    def site_params
      params.require(:site).permit(:name, :feed_url)
    end
end
