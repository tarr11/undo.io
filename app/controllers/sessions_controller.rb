class SessionsController < Devise::SessionsController

  before_filter :force_ssl, :only => :new
  #@respond_to_mobile_requests :skip_xhr_requests => false

  private

   def force_ssl
     if !request.ssl? && Rails.env.production?
       redirect_to :protocol => 'https'
     end
   end

end