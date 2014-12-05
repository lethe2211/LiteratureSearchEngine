class Session < ActiveRecord::Base
  has_many :access
  has_many :relevance
end
