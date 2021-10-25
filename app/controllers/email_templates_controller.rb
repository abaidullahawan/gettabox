# frozen_string_literal: true

# Email Template Setup
class EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: %i[show edit update destroy]

  # GET /email_templates or /email_templates.json
  def index
    @email_templates = EmailTemplate.all
    new
  end

  # GET /email_templates/1 or /email_templates/1.json
  def show; end

  # GET /email_templates/new
  def new
    @email_template = EmailTemplate.new
    @types = ['Default']
    @names = ['PurchaseOrder']
  end

  # GET /email_templates/1/edit
  def edit
    @types = ['Default']
    @names = ['PurchaseOrder']
  end

  # POST /email_templates or /email_templates.json
  def create
    @email_template = EmailTemplate.new(email_template_params)

    flash[:notice] = if @email_template.save
                       'Email Template successfully created.'
                     else
                       @email_template.errors.full_messages
                     end
    redirect_to email_templates_path
  end

  # PATCH/PUT /email_templates/1 or /email_templates/1.json
  def update
    flash[:notice] = if @email_template.update(email_template_params)
                       'Email Template successfully updated.'
                     else
                       @email_template.errors.full_messages
                     end
    redirect_to email_templates_path
  end

  # DELETE /email_templates/1 or /email_templates/1.json
  def destroy
    @email_template.destroy
    respond_to do |format|
      format.html { redirect_to email_templates_url, notice: 'Email template was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def email_template_params
    params.require(:email_template).permit(:template_type, :template_name, :subject, :body)
  end
end
