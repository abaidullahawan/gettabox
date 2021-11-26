class MailServiceRulesController < ApplicationController
  before_action :set_mail_service_rule, only: %i[ show edit update destroy ]

  # GET /mail_service_rules or /mail_service_rules.json
  def index
    @mail_service_rules = MailServiceRule.all
  end

  # GET /mail_service_rules/1 or /mail_service_rules/1.json
  def show
  end

  # GET /mail_service_rules/new
  def new
    @mail_service_rule = MailServiceRule.new
  end

  # GET /mail_service_rules/1/edit
  def edit
  end

  # POST /mail_service_rules or /mail_service_rules.json
  def create
    @mail_service_rule = MailServiceRule.new(mail_service_rule_params)

    respond_to do |format|
      if @mail_service_rule.save
        format.html { redirect_to @mail_service_rule, notice: "Mail service rule was successfully created." }
        format.json { render :show, status: :created, location: @mail_service_rule }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @mail_service_rule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mail_service_rules/1 or /mail_service_rules/1.json
  def update
    respond_to do |format|
      if @mail_service_rule.update(mail_service_rule_params)
        format.html { redirect_to @mail_service_rule, notice: "Mail service rule was successfully updated." }
        format.json { render :show, status: :ok, location: @mail_service_rule }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @mail_service_rule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mail_service_rules/1 or /mail_service_rules/1.json
  def destroy
    @mail_service_rule.destroy
    respond_to do |format|
      format.html { redirect_to mail_service_rules_url, notice: "Mail service rule was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mail_service_rule
      @mail_service_rule = MailServiceRule.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def mail_service_rule_params
      params.require(:mail_service_rule).permit(:description, :service_name)
    end
end
