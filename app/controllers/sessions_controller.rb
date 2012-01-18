class SessionsController < Devise::SessionsController

  before_filter :force_ssl, :only => :new

  private

   def force_ssl
     if !request.ssl? && Rails.env.production?
       redirect_to :protocol => 'https'
     end
   end

end