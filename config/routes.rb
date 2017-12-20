Rails.application.routes.draw do
  resources :posts, only:[:create, :update]
  get 'posts/iplist', to: 'posts#iplist'
  get 'posts/top/:quantity', to: 'posts#top'
  get 'seed(/posts/:posts)(/users/:users)(/ips/:ips)(/rates/:rates)', to: 'seed#seed'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
