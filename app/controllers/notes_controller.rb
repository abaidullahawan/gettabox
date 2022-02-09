# frozen_string_literal: true

# add notes
class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :note_params, only: %i[create]

  def index; end

  def show; end

  def new; end

  def create
    order = ChannelOrder.find_by(id: params[:note]["reference_id"])
    note = Note.new(note_params)
    note.user_id = current_user.id
    if note.save
      if params[:note]["reference_type"] == "ChannelOrder"
        order.update(change_log: "#{note.message}, #{order.id}, #{order.order_id}, #{current_user.personal_detail.full_name}")
      end
      flash[:notice] = 'Note added successfully'
    else
      flash[:alert] = note.errors.full_messages
    end
    redirect_to request.referrer
  end

  def edit; end

  def update; end

  private

  def note_params
    params.require(:note).permit(:reference_type, :reference_id, :message)
  end
end
