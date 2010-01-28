require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "SociallyActive" do
	
	it "should integrate follower methods properly" do
		%w(followers following following? followed_by?).each do |method|
	   	FollowerClass.new.methods.include?(method).should be_true
		end
	end
	
	it "should integrate friend methods properly" do
		%w(friends outgoing_friend_requests incoming_friend_requests extended_network).each do |method|
	   	FriendClass.new.methods.include?(method).should be_true
		end
	end
	
	
	it "should validate relationships properly" do
		a = FollowerClass.create
		b = FollowerClass.create
		
		r = Relationship.new(:requestor => a, :requestee => b, :restricted => false)
		r.should be_valid
		
		r2 = Relationship.new(:requestor => a, :restricted => false)
		r2.should_not be_valid
	
		r3 = Relationship.new(:requestee => b, :restricted => true)
		r3.should_not be_valid
	end
	
end

describe "SociallyActive -- Follower" do
	it "should generate relationships and return proper counts" do
		a = FollowerClass.create
		b = FollowerClass.create

		a.follow(b)
		
		r = Relationship.last

		r.requestor.should eql(a)
		r.requestee.should eql(b)
		r.blocked.should be_false
		
		a.following_count.should eql(1)
		a.follower_count.should eql(0)
		
		b.following_count.should eql(0)
		b.follower_count.should eql(1)
	end
	
	it "should generate and destroy relationships from socially_active models" do
		a = FollowerClass.create
		b = FollowerClass.create
		
		a.follow(b)
		
		a.following_count.should eql(1)
		
		a.unfollow(b)
		a.following_count.should eql(0)
		
	end
		
	it "should restrict relationships properly" do
		a = FollowerClass.create
		b = FollowerClass.create

		r = a.follow(b)
		
		b.block(a)
		
		a.following_count.should eql(0)
		b.follower_count.should eql(0)
		
		r.reload
		r.blocked.should be_true
		
		lambda { a.follow(b) }.should raise_error(Socially::Active::StalkerError)
		
		a.following_count.should eql(0)
		b.follower_count.should eql(0)
	
		b.follow(a)
		
		a.follower_count.should eql(1)
		b.following_count.should eql(1)
		
	end
	
	
	it "should collect relationship personnel properly" do
		a = FollowerClass.create
		b = FollowerClass.create
		c = FollowerClass.create
		d = FollowerClass.create
		e = FollowerClass.create
		
		a.follow(b)
		b.follow(c)
		a.follow(c)
		c.follow(d)
		e.follow(c)
		
		a.followers.empty?.should be_true
		a.following.size.should eql(2)
		a.following.sort{|m,n| m.id <=> n.id}.should eql([b,c])
		
		c.followers.size.should eql(3)
		c.followers.sort{|m,n| m.id <=> n.id}.should eql([a,b,e])

		a.extended_network.include?(d).should be_true
		a.extended_network.include?(e).should be_false
	end
	
	
	
	
	
end

