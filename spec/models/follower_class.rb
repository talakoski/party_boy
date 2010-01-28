class FollowerClass < ActiveRecord::Base
	include Social::Lite
	
	acts_as_followable
end
