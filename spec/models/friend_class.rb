class FriendClass < ActiveRecord::Base
	include Social::Lite
	
	acts_as_friend
end
