class MembersController < ApplicationController
  layout "txt411/application"

  def new
    @member = Member.new
  end

  def create
    @member = Member.new(params[:member])
    if @member.save
      return redirect_to(member_path(@member))
    else
      render(:action => "new")
    end
  end

  def show
    @member = Member.find(params[:id])
  end
end
