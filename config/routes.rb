GplusPhotohuntSeverRuby::Application.routes.draw do

  get 'api/themes', to: 'themes#index'

  get 'api/photos', to: 'photos#index'

  post 'api/photos', to: 'photos#create'

  delete 'api/photos', to: 'photos#delete'

  post 'api/connect', to: 'connections#create'

  post 'api/images', to: 'photos#get_url'

  get 'api/friends', to: 'friends#index'

  get 'api/users', to: 'users#index'

  post 'api/disconnect', to: 'connections#destroy'

  put 'api/votes', to: 'votes#create'

  get 'photo.html', to: 'photos#photo'

  get 'invite.html', to: 'invites#invite'

end
