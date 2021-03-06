class TranslationsController < ApplicationController
  before_filter :find_locale
  before_filter :retrieve_key, only: [:create, :update]
  before_filter :find_translation, only: [:edit, :update]
  before_action :authenticate_user!
  before_action :authorize_user
  layout 'admin'
  
  def index
    if params.key?("key")
      @translations = Translation.where("locale = ? AND translations.key LIKE ?", @locale, params[:key]+'%')
    else
      @translations = Translation.locale(@locale)
    end
  end

  def new
    @translation = Translation.new(locale: @locale, key: params[:key])
  end

  def create
    @translation = Translation.new(translation_params)
    if @translation.value == default_translation_value
      flash[:alert] = "Your new translation is the same as the default."
      render :new
    else
      if @translation.save
        flash[:success] = "Translation for #{ @key } updated."
        I18n.backend.reload!
        redirect_to locale_translations_url(@locale, :params => { key: params[:key] })
      else
        render :new
      end
    end
  end

  def edit
  end

  def update
    if @translation.update(translation_params)
      flash[:notice] = "Translation for #{ @key } updated."
      I18n.backend.reload!
      redirect_to locale_translations_url(@locale, :params => { key: translation_params[:key].split('.').first })
    else
      render :edit
    end
  end

  def destroy
    Translation.destroy(params[:id])
    I18n.backend.reload!
    redirect_to locale_translations_url(@locale, :params => { key: params[:key] })
  end

  private

  def find_locale
    @locale = params[:locale_id]
  end

  def find_translation
    @translation = Translation.find(params[:id])
  end

  def retrieve_key
    @key = params[:i18n_backend_active_record_translation][:key]
  end

  def translation_params
    params.require(:i18n_backend_active_record_translation).permit(:locale,
      :key, :value)
  end

  def default_translation_value
    I18n.t(@translation.key, locale: @locale)
  end
  
  def authorize_user
    if !current_user.has_role? :admin
      flash[:alert] = "You need Admin privilege to update Content"
      redirect_to admin_path
    end
  end
end
