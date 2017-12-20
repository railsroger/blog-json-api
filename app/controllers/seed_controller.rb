class SeedController < ApplicationController


    # GET
    # /api/seed  <-- default, posts = 200000, users = 100, ips = 50, marks = 50% of posts
    # /api/seed/posts/:posts/users/:users/ips/:ips/marks/:marks
    def seed

      if populate(params)
        render plain: "Database is populated.\n", status: :ok
        else
          render plain: "Database was not populated.\n", status: 501
      end
    end


      def populate (params)

        logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = nil

        posts_count = (params[:posts] || 200).to_i
        users_count = (params[:users] || 100).to_i
        ips_count = (params[:ips] || 50).to_i
        rate_count = ((1..100).include?(params[:rate].to_i) ? params[:rate] : 50).to_i # in percents

        print "Creating #{users_count} users... " unless Rails.env.test?
          User.delete_all

          users = []
          users_count.times do |i|
            # users << User.new(login: Faker::Internet.email)
            users << User.new(nickname: "user#{i+1}@gmail.com")
          end

          User.import users
        puts 'OK' unless Rails.env.test?


        print "Creating #{ips_count} addresses... " unless Rails.env.test?
          ips = []
          ips_count.times do
            ips << Faker::Internet.ip_v4_address
          end
        puts 'OK' unless Rails.env.test?


        print "Creating #{posts_count} posts... " unless Rails.env.test?
          Post.delete_all
          user_ids = (User.last.id - users_count + 1)..(User.last.id)

          bulk_size = 10000
          counts_array = []
          quotient, rest = posts_count.divmod(bulk_size)
          counts_array << rest if rest > 0
          quotient.times {counts_array << bulk_size}

          i = 1
          counts_array.each do |k|
            posts = []
            k.times do
              posts << Post.new(
                user_id: rand(user_ids),
                ip: ips[rand(0...ips_count)],
                title: "Title #{i}",
                content: "Content N#{i}"
                )
              i += 1
            end

            Post.import posts
          end
        puts 'OK' unless Rails.env.test?


        rates_q = (Post.count.to_f / 100 * rate_count).round
        print "Creating #{rates_q} rates that is #{rate_count}\% of #{posts_count} posts... " unless Rails.env.test?
        Rate.delete_all

          min_rate_id = Post.first.id
          rates = []
          (min_rate_id..(min_rate_id + rates_q - 1)).each do |i|

            rates << Rate.new(post_id: i, rate: rand(1.0..5.0).round(2), rate_count: rand((1..1000)))

          end

          Rate.import rates

        puts 'OK' unless Rails.env.test?

        ActiveRecord::Base.logger = logger

        return true
      end

end
