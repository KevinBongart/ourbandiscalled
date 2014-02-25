class RecordController < ApplicationController
  def new
    redirect_to slug_path Record.create
  end

  def show
    @record = Record.find_by_slug params[:slug]
  end

  def short_url
    redirect_to slug_path Record.find params[:id]
  end
end
