module Socially
	module Active
		class IdentityTheftError < StandardError; end
			
		def self.included(klazz)
			klazz.extend(Socially::Active::ClassMethods)
		end
		
		module ClassMethods
			
			def acts_as_followable
				with_options :class_name => 'Relationship', :dependent => :destroy do |klazz|
				 klazz.has_many :followings, :as => :requestee
				 klazz.has_many :follows, :as => :requestor
				end
				
				include Socially::Active::RelateableInstanceMethods
				include Socially::Active::FollowableInstanceMethods
			end
			
			def acts_as_friend
				with_options :class_name => 'Relationship', :dependent => :destroy do |klazz|
					klazz.has_many :outgoing_friendships, :as => :requestor, :include => :requestee
					klazz.has_many :incoming_friendships, :as => :requestee, :include => :requestor
				end
				
				include Socially::Active::RelateableInstanceMethods
				include Socially::Active::FriendlyInstanceMethods
			end
			
		end
		
		
		module RelateableInstanceMethods
		
		private
		
			def super_class_name(obj = self)
				if obj.class.superclass != ActiveRecord::Base
					return obj.class.superclass.name
				end
				return obj.class.name
			end
			
			def get_relationship_to(requestee)
				requestee && Relationship.unblocked.find(:first, :conditions => ['requestor_id = ? and requestor_type = ? and requestee_id = ? and requestee_type = ?', self.id, super_class_name, requestee.id, super_class_name(requestee)]) || nil
			end
			
			def get_relationship_from(requestor)
				requestor && Relationship.unblocked.find(:first, :conditions => ['requestor_id = ? and requestor_type = ? and requestee_id = ? and requestee_type = ?', requestor.id, super_class_name(requestor), self.id, super_class_name]) || nil
			end
			
		end
		
		module FollowableInstanceMethods
		
			def following?(something)
				!!(something && Relationship.unblocked.count(:conditions => ['requestor_id = ? and requestor_type = ? and requestee_id = ? and requestee_type = ?', self.id, super_class_name, something.id, super_class_name(something)]) > 0)
			end
			
			def followed_by?(something)
				!!(something && Relationship.unblocked.count(:conditions => ['requestor_id = ? and requestor_type = ? and requestee_id = ? and requestee_type = ?', something.id, super_class_name(something), self.id, super_class_name]) > 0)
			end
			
			def follow(something)
				Relationship.create(:requestor => self, :requestee => something, :restricted => false) if !following?(something)
			end
			
			def unfollow(something)
				(rel = get_relationship_to(something)) && rel.destroy
			end
			
			def block(something)
				(rel = get_relationship_from(something)) && rel.update_attributes({:restricted => true})
			end
			
			def follower_count(type = nil)
				Relationship.unblocked.from_type(type).size
			end
			
			def following_count(type = nil)
				Relationship.unblocked.to_type(type).size
			end
			
			def followers(type = nil)
				relationships_from(type).collect{|r| r.requestor}
			end
			
			def following(type = nil)
				relationships_to(type).collect{|r| r.requestee}
			end
			
			def method_missing(method, *args)
				if method.id2name =~ /^(.+)_followers$/
					followers($1.singularize.classify)
				elsif method.id2name =~ /^(.+)_following$/
					following($1.singularize.classify)
				else
					super
				end
			end
			
		private
			
			def relationships_to(type)
				self.follows.unblocked.to_type(type).all(:include => [:requestee])
			end
			
			def relationships_from(type)
				self.followings.unblocked.from_type(type).all(:include => [:requestor])
			end
			
		end
		
		module FriendlyInstanceMethods
			
			def friends
				(outgoing_friendships.accepted + incoming_friendships.accepted).collect{|r| [r.requestor, r.requestee]}.flatten.uniq - [self]
			end
			
			def extended_network
				friends.collect{|f| f.methods.include?(:friends) && f.friends || []}.flatten.uniq - [self]
			end
			
			def outgoing_friend_requests
				self.outgoing_friendships.unaccepted.all
			end
			
			def incoming_friend_requests
				self.incoming_friendships.unaccepted.all
			end
			
			def is_friends_with?(something)
				arr = something && [self.id, super_class_name, super_class_name(something), something.id]
				arr && Relationship.accepted.count(:conditions => [(['(requestor_id = ? AND requestor_type = ? AND requestee_type = ? AND requestee_id = ?)']*2).join(' OR '), arr, arr.reverse].flatten) > 0
			end
			
			def pending?(something)
				arr = something && [self.id, super_class_name, super_class_name(something), something.id]
				arr && Relationship.unaccepted.count(:conditions => [(['(requestor_id = ? AND requestor_type = ? AND requestee_type = ? AND requestee_id = ?)']*2).join(' OR '), arr, arr.reverse].flatten) > 0
			end
			
			def friend_count
				arr = [self.id, super_class_name]
				Relationship.accepted.count(:conditions => ['(requestor_id = ? AND requestor_type = ?) OR (requestee_id = ? and requestee_type = ?)', arr, arr].flatten)
			end
			
			def request_friendship(friendship_or_something)
				rel = relationship_from(friendship_or_something)
				rel.nil? && Relationship.create(:requestor => self, :requestee => friendship_or_something, :restricted => true) || rel.update_attributes(:restricted => false)
			end
			
			def deny_friendship(friendship_or_something)
				(rel = relationship_from(friendship_or_something)) && rel.destroy
			end
			
			alias_method :reject_friendship, :deny_friendship
			alias_method :accept_friendship, :request_friendship
			
		private
		
			def relationship_from(friendship_or_something)
				if friendship_or_something && friendship_or_something.class == Relationship
					raise(Socially::Active::IdentityTheftError, "#{self.class.name} with id of #{self.id} tried to access Relationship #{friendship_or_something.id}") if 	!(friendship_or_something.requestor == self || friendship_or_something.requestee == self)
					friendship_or_something
				else
					arr = friendship_or_something && [self.id, super_class_name, super_class_name(friendship_or_something), friendship_or_something.id]
					arr && Relationship.find(:first, :conditions => [(['(requestor_id = ? AND requestor_type = ? AND requestee_type = ? AND requestee_id = ?)']*2).join(' OR '), arr, arr.reverse].flatten) || nil
				end
			end	
		end
	end
end