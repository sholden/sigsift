class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern

  helper_method :current_account

  private

  def current_account
    Current.user&.account
  end
end
