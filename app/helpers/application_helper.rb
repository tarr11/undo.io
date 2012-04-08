module ApplicationHelper

  def create_google_analytics_event(category, action, label, value)

    unless flash[:analytics]
     flash[:analytics] = []
    end

    ga_event = GoogleAnalyticsEvent.new.tap do |event|
      event.category = category
      event.action = action
      event.label = label
      event.value = value
    end 

    flash[:analytics].push ga_event
  end
  # devise helpers http://stackoverflow.com/questions/4081744/devise-form-within-a-different-controller
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
