class PostsController < ApplicationController


# 1. Создать пост. Принимает заголовок и содержание поста (не могут быть пустыми), а также логин и айпи автора. Если автора с таким логином еще нет, необходимо его создать. Возвращает либо атрибуты поста со статусом 200, либо ошибки валидации со статусом 422.
    # POST /posts
    def create

      # Server accepts only json content type
      if request.content_type == 'application/json'

        # Client has to accept any or json content type
        if request.accept && ( request.accept.include?('*/*') || request.accept.include?('application/json') )

          errors = []

          errors << 'Title is not valid' if !post_params || post_params[:title].blank?
          errors << 'Content is not valid' if !post_params || post_params[:content].blank?
          errors << 'Nickname is not valid' if !user_params || user_params[:nickname].blank?

          if errors.empty?

            @user = User.find_or_create_by(nickname: user_params[:nickname])
            @post = @user.posts.new(post_params)
            @post.ip = request.ip

            if @post.save
              render json: @post.to_json(only: [:id, :title, :content]), status: 200
              # render json: @post, status: :created
              else
                errors << 'Post did not save'
                render json: errors, status: 422
            end

            else
              render json: errors, status: 422
          end

          else
            render plain: "We don't issue '#{request.accept}' content type", status: 400
        end

        else
          render plain: "We don't accept '#{request.content_type}' content type", status: 400
      end

    end


    # 2. Поставить оценку посту. Принимает айди поста и значение, возвращает новый средний рейтинг поста. Важно: экшен должен корректно отрабатывать при любом количестве конкурентных запросов на оценку одного и того же поста.
    # PUT /api/posts/:id
    def update

      if request.content_type == 'application/json'

        if request.accept && ( request.accept.include?('*/*') || request.accept.include?('application/json') )

          if rate_params && (1..5).include?(rate_params[:rate].to_i)

            new_rate = rate_params[:rate].to_i
            begin
              post = Post.find_by(id: params[:id])
              if post
                Rate.transaction do
                # post = Post.find_by(id: params[:id])

                  # Find mark of a post by id or create new
                  @rate = Rate.lock.find_or_create_by!(post_id: post.id)
                  @rate.rate = @rate.rate || 0
                  @rate.rate_count = @rate.rate_count || 0

                  # Compute average mark and save new average mark and total marks quantity
                  @rate.rate = ((@rate.rate * @rate.rate_count + new_rate) / (@rate.rate_count + 1)).round(2)
                  @rate.rate_count += 1

                  @rate.save!
                end

                else
                  raise RuntimeError, 'Post is not exist'
              end

              # ActiveRecord::TransactionIsolationError   transaction
              # ActiveRecord::StatementInvalid            create!
              # ActiveRecord::RecordNotSaved              save!
              rescue ActiveRecord::TransactionIsolationError, ActiveRecord::StatementInvalid, ActiveRecord::RecordNotSaved, RuntimeError
                # If an error is raised
                render plain: "Not saved", status: 422

              else
                # If no errors are raised
                render json: {avg_mark: @mark.mark}, status: 200
            end

            else
              render plain: 'Mark is not valid',status: 400

          end

          else
            render plain: "We don't issue '#{request.accept}' content type", status: 400
        end

        else
          render plain: "We don't accept '#{request.content_type}' content type", status: 400
      end
    end


    # 3. Получить топ N постов по среднему рейтингу. Просто массив объектов с заголовками и содержанием.
    # GET /api/posts/top/:quantity
    def top

      if request.accept && ( request.accept.include?('*/*') || request.accept.include?('application/json') )

        if params[:quantity] && (params[:quantity].to_i > 0)
          posts = ActiveRecord::Base.connection.execute("
                    select title, content from posts where rate_value is not null
                      order by rate_value desc, rate_count desc
                      limit #{params[:quantity]};
                  ")

          render json: posts, status: 200

          else
            render plain: 'Post quantity is not valid', status: 400

        end

        else
          render plain: "We don't issue '#{request.accept}' content type", status: 400
      end

    end


    # 4. Получить список айпи, с которых постило несколько разных авторов. Массив объектов с полями: айпи и массив логинов авторов.
    # GET /api/posts/iplist
    def iplist

      if request.accept && ( request.accept.include?('*/*') || request.accept.include?('application/json') )

        ips = ActiveRecord::Base.connection.execute('
                select ip, (array_agg(distinct nickname)) as nicknames
                  from posts inner join users
                    on posts.user_id = users.id
                  group by ip
                    having array_length(array_agg(distinct nickname), 1) > 1;
              ')

        render json: ips, status: 200

        else
          render plain: "We don't issue '#{request.accept}' content type", status: 400
      end

    end

    private

    def post_params
      params.require(:post).permit(:title, :content) if params[:post].present?
    end

    def user_params
      params.require(:user).permit(:nickname) if params[:user].present?
    end

    def rate_params
      params.require(:rate).permit(:rate) if params[:rate].present? && params[:rate][:rate].present?
    end

end
