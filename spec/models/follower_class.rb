class FollowerClass < ActiveRecord::Base
	include Party::Boy
	
	acts_as_followable
end
