class PartyBoyGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory "app/models"
      m.template "model.rb", "app/models/relationship.rb"
      
      m.migration_template 'migration.rb', 'db/migrate'
    end
  end
  
  def file_name
    "party_boy_migration"
  end
end