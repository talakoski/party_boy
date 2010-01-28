class Relationship < ActiveRecord::Base

	named_scope :restricted, :conditions => ['relationships.restricted = ?', true]
	named_scope :unrestricted, :conditions => ['relationships.restricted = ?', false]
	named_scope :to_type, lambda {|type| type && {:conditions => ['relationships.requestee_type = ?', type.to_s]} || {}}
	named_scope :from_type, lambda {|type| type && {:conditions => ['relationships.requestor_type = ?', type.to_s]} || {}}
	
	default_scope :order => 'created_at DESC'
	
	with_options :polymorphic => true do |klazz|
		klazz.belongs_to :requestor
		klazz.belongs_to :requestee
	end
	
	validates_presence_of :requestor, :requestee
	
	
	def blocked?
		self.restricted
	end
	
	def accepted?
		!self.restricted
	end
	
	class << self
		alias_attribute :blocked, :restricted
		alias_attribute :unblocked, :unrestricted
	
		alias_attribute :unaccepted, :restricted
		alias_attribute :accepted, :unrestricted
	end
end
