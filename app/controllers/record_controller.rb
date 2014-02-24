class RecordController < ApplicationController
  def new
    redirect_to Record.create
  end

  def show
    @record = Record.find_by_slug params[:id]
  end
end
