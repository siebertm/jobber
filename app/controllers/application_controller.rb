# stub out ApplicationController. in the rails application, it exists, but not
# when running the tests alone
if Rails.env.test?
  class ApplicationController < ActionController::Base
  end
end

