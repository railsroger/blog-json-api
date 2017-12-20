class Post < ApplicationRecord
  belongs_to :user
  has_one :rate, dependent: :destroy
end
