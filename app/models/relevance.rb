class Relevance < ActiveRecord::Base
  belongs_to :session
  belongs_to :literature
end
