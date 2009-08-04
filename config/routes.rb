ActionController::Routing::Routes.draw do |map|
  map.resources :jobs, :controller => "jobber/jobs"
end
