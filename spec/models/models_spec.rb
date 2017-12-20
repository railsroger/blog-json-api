require 'rails_helper'

describe "Models" do

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

  #to determine class existence
  def class_exists?(class_name)
    eval("defined?(#{class_name}) && #{class_name}.is_a?(Class)")
  end


  describe "User" do

    it "should be existed" do
      expect(class_exists?('User'))
    end

    it "should has many posts" do
      u_posts = User.first.posts
      posts = Post.where(user_id: User.first.id)
      expect(u_posts).to eq posts
    end

  end


  describe "Rate" do

    it "should be existed" do
      expect(class_exists?('Rate'))
    end

    it "should belongs to post" do
      post = Post.first
      rate = Rate.find_or_create_by(post_id: post.id)

      post_m = rate.post
      expect(post).to eq post_m
    end

  end


  describe "Post" do

    it "should be existed" do
      expect(class_exists?('Post'))
    end

    it "should belongs to user" do
      post_u = Post.where.not(user_id: nil).first.user
      user = User.find_by(id: post_u.id)
      expect(post_u).to eq user
    end

    it "should has one Rate" do
      rate = Rate.where.not(post_id: nil).first
      post_m = Post.find(rate.post_id).rate
      expect(post_m).to eq rate
    end

    it "Rate should be dependented on destroy" do
      rate = Rate.where.not(post_id: nil).first
      post = Post.find(rate.post_id)

      post.destroy
      rate_d = Rate.find_by(id: rate.id)
      expect(rate_d).to eq nil
    end

  end


  describe "Trigger function get_rate_for_post()" do

    it "should be implemented" do
      post = Post.where.not(rate_count: nil).first
      rate = post.rate

      expect(post).not_to be_nil
      expect(rate).not_to be_nil

      rate.update(rate_count: 99, rate: 3.33)
      expect(Rate.find(rate.id).rate_count).to eq 99
      expect(Rate.find(rate.id).rate).to eq 3.33
      expect(Post.find(post.id).rate_count).to eq 99
      expect(Post.find(post.id).rate_value).to eq 3.33

      rate.update(rate_count: nil, rate: nil)
      expect(Rate.find(rate.id).rate_count).to be_nil
      expect(Rate.find(rate.id).rate).to be_nil
      expect(Rate.find(rate.id).post.rate_count).to be_nil
      expect(Rate.find(rate.id).post.rate_value).to be_nil
    end

  end

end
