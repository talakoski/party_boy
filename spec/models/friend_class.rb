class FriendClass < ActiveRecord::Base
	include Socially::Active
	
	acts_as_friend
end
