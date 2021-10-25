class EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: %i[ show edit update destroy ]

  # GET /email_templates or /email_templates.json
  def index
    @email_templates = EmailTemplate.all
    new
  end

  # GET /email_templates/1 or /email_templates/1.json
  def show
  end

  # GET /email_templates/new
  def new
    @email_template = EmailTemplate.new
    @types = ["Default"]
    @names = ["PurchaseOrder"]
  end

  # GET /email_templates/1/edit
  def edit
    @types = ["Default"]
    @names = ["PurchaseOrder"]
  end

  # POST /email_templates or /email_templates.json
  def create
    @email_template = EmailTemplate.new(email_template_params)

    if @email_template.save
      flash[:notice] = "Email Template successfully created."
      redirect_to email_templates_path
    else
      flash[:notice] = @email_template.errors.full_messages
      redirect_to email_templates_path
    end
  end

  # PATCH/PUT /email_templates/1 or /email_templates/1.json
  def update
    if @email_template.update(email_template_params)
      flash[:notice] = "Email Template successfully created."
      redirect_to email_templates_path
    else
      flash[:notice] = @email_template.errors.full_messages
      redirect_to email_templates_path
    end
  end

  # DELETE /email_templates/1 or /email_templates/1.json
  def destroy
    @email_template.destroy
    respond_to do |format|
      format.html { redirect_to email_templates_url, notice: "Email template was successfully destroyed." }
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
