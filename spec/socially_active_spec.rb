require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "SociallyActive" do
	it "integrate follower methods properly" do
		%w(followers following following? followed_by?).each do |method|
	   	FollowerClass.new.methods.include?(method).should be_true
			puts "Successfully incorporated method #{method} into Follower Class"
		end
	end
	
	it "integrate friend methods properly" do
		%w(friends outgoing_friend_requests incoming_friend_requests extended_network).each do |method|
	   	FriendClass.new.methods.include?(method).should be_true
			puts "Successfully incorporated method #{method} into Friend Class"
		end
	end
	
end
