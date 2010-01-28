class FollowerClass < ActiveRecord::Base
	include Socially::Active
	
	acts_as_followable
end
