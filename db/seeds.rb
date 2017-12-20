# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
params = {}
params[:posts] = 200000
params[:users] = 100
params[:ips] = 50
params[:rates] = 50 # percents of posts

# /app/controllers/api/seed_controller.rb
SeedController.new.populate(params)
