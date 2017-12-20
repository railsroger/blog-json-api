require 'rails_helper'

RSpec.describe PostsController, type: :request do

  before(:all) do

    params = {}
    params[:posts] = 2
    params[:users] = 2
    params[:ips] = 2
    params[:rates] = 50 # percents of posts

    # /app/controllers/api/seed_controller.rb
    SeedController.new.populate(params)
  end

  after(:all) do
    Post.delete_all
    User.delete_all
    Rate.delete_all
  end

  describe "POST create - create post" do

    let(:title) { 'Title_1' }
    let(:content) { 'Content_1'}
    let(:nickname) { 'User_1' }
    let(:post_params) { {post: {title: title, content: content }, user: {nickname: nickname}}.to_json }


    it "without Content-Type json in headers" do
      headers = { "CONTENT_TYPE" => "*/*" }
      post '/posts/', '', headers
      expect(response.status).to eq 400
      expect(response.body).to include("We don't accept")
    end

    it "with Content-Type json in headers" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/xml" }
      post '/posts', '', headers
      expect(response.status).to eq 400
      expect(response.body).to include("We don't issue")
    end

    it "with Content-Type json and Accept json in headers" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
      post '/posts', '', headers
      expect(response.status).to eq 422
      expect(response.body).to include(['Title is not valid', 'Content is not valid', 'Login is not valid'].to_json)
    end

    it "with expected parameters" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
      post '/posts', post_params, headers

      post_id = Post.last.id

      expect(response.status).to eq 200
      expect(response.content_type).to eq "application/json"
      expect(response.body).to eq({ id: post_id, title: title, content: content }.to_json)
    end

    it "post is not saved" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
      new_params = {post: {title: 'kos', content: 'kos' }, user: {nickname: 'kos'}}.to_json

      allow_any_instance_of(Post).to receive(:save).and_return(false)
      post '/posts', new_params, headers

      expect(response.status).to eq 422
      expect(response.body).to include("Post did not save")

      expect(Post.where(title: 'kos').count).to eq 0
    end

  end


  describe "PUT update - update rate" do

    let(:params) { {rate: {rate: 4 }} }

    it "without Content-Type json in headers" do
      headers = { "CONTENT_TYPE" => "*/*" }
      rate = Rate.where.not(rate: nil).first
      post = rate.post

      put "/posts/#{post.id}", '', headers
      expect(response.status).to eq 400
      expect(response.body).to include("We don't accept")
    end

    it "with Content-Type json in headers" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/xml" }
      rate = Rate.where.not(rate: nil).first
      post = rate.post

      put "/posts/#{post.id}", '', headers
      expect(response.status).to eq 400
      expect(response.body).to include("We don't issue")
    end

    it "with Content-Type json and Accept json in headers" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
      rate = Rate.where.not(rate: nil).first
      post = rate.post

      put "/posts/#{post.id}", '', headers
      expect(response.status).to eq 400
      expect(response.body).to include('Rate is not valid')
    end

    it "with expected parameters" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
      rate = Rate.where.not(rate: nil).first
      post = rate.post

      put "/posts/#{post.id}", params.to_json, headers

      expect(response.status).to eq 200
      expect(response.content_type).to eq "application/json"
      expect(rate.rate_count + 1).to eq Rate.find(rate.id).rate_count

      rate_value = ((rate.rate * rate.rate_count + params[:rate][:rate]) / (rate.rate_count + 1)).round(2)
      expect(response.body).to eq({ avg_rate: rate_value}.to_json)
    end

    it "with invalid post id" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
      post = Post.first
      post.destroy

      put "/posts/#{post.id}", params.to_json, headers

      expect(response.status).to eq 422
      expect(response.body).to include("Not saved")

      rate = Rate.where(post_id: post.id).first

      expect(rate).to be_nil
    end


    it "should transaction method error" do
      headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
      new_params = {rate: {rate: 5 }}.to_json

      Post.first.rate.update(rate: nil, rate_count: nil)
      rate = Rate.where(rate_count: nil).first

      # ActiveRecord::TransactionIsolationError   transaction
      allow(Rate).to receive(:transaction).and_raise( ActiveRecord::TransactionIsolationError )
      put "/posts/#{rate.post.id}", new_params, headers

      expect(response.status).to eq 422
      expect(response.body).to include("Not saved")
      expect(Rate.find(rate.id).rate_count).to eq rate.rate_count
    end

  end


  describe "GET top - get top posts" do

    let(:quantity) { Rate.where.not(rate_count: nil).count }

    it "without Accept json in headers" do
      headers = { "ACCEPT" => "application/xml" }
      get "/posts/top/asd", '', headers
      expect(response.status).to eq 400
      expect(response.body).to include("We don't issue")
    end

    it "with invalid param post quantity" do
      headers = { "ACCEPT" => "application/json" }
      get "/posts/top/asd", '', headers
      expect(response.status).to eq 400
      expect(response.body).to include("Post quantity is not valid")
    end

    it "with valid param post quantity" do
      headers = { "ACCEPT" => "application/json" }
      get "/posts/top/#{quantity}", '', headers

      posts = Post.select(:title, :content).where.not(rate_value: nil).order(rate_value: :desc, rate_count: :desc).limit(quantity)

      expect(response.status).to eq 200
      expect(response.body).to eq posts.to_json(only: [:title, :content])
    end

  end


  describe "GET iplist - get ip list" do

    it "without Accept json in headers" do
      headers = { "ACCEPT" => "application/xml" }
      get "posts/iplist", '', headers
      expect(response.status).to eq 400
      expect(response.body).to include("We don't issue")
    end

    it "with Accept */* in headers" do
      headers = { "ACCEPT" => "*/*" }
      get "posts/iplist", '', headers

      ips = ActiveRecord::Base.connection.execute('
              select ip, (array_agg(distinct nickname)) as nicknames
                from posts inner join users
                  on posts.user_id = users.id
                group by ip
                  having array_length(array_agg(distinct nickname), 1) > 1;
            ')

      expect(response.status).to eq 200
      expect(response.body).to eq ips.to_json
    end

  end

end
