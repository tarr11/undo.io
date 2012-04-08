class RegistrationsController < Devise::RegistrationsController
    
  protected
  def after_inactive_sign_up_path_for(resource)
    url_for :controller=> 'home', :action=>'please_confirm'
  end

  def after_sign_up_path_for(resource)
    url_for :controller=> 'home', :action=>'please_confirm'
  end
end
