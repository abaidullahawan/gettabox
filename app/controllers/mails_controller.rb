# frozen_string_literal: true

# Sending mail as a admin
class MailsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def show
  end

  def new
  end

  def create
    if MailMailer.with(subject: params[:subject], to: params[:to], cc: params[:cc], message: params[:message]).new_email.deliver
      flash[:notice] = 'Mail sent successfully'
    else
      flash[:alert] = "Mail can't be sent at this moment"
    end
    redirect_to mails_path
  end

  def edit
  end

  def update
  end

  private

  def mail_params
  end
end
