require 'rubygems'
gem 'sqlite3-ruby'
require 'sqlite3'
require 'active_record'

module SpecHelperFunctions
  def setup_db_connection
    ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/../log/test.log")
    # ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database  => ':memory:'
    ActiveRecord::Base.establish_connection :adapter => 'mysql', :database  => 'acts_as_mailable', :user => 'root'
    ActiveRecord::Migration.verbose = false
  end

  def run_migration(name, method)
    path = File.expand_path( File.dirname(__FILE__)+"/../generators/mailable/templates/migrate" )
    require path + "/#{name}"
    klass = name.camelize.constantize
    klass.send(method)
  end

  def setup_db
    ActiveRecord::Schema.define do
      create_table :users, :force => true do |t|
        t.string :name
      end
    end
    run_migration("create_conversations", :up)
    run_migration("create_deliveries", :up)
    run_migration("create_mails", :up)
    run_migration("create_messages", :up)
    run_migration("create_messages_recipients", :up)
    run_migration("add_new_mail_count", :up)
  end

  def teardown_db
    run_migration("create_conversations", :down)
    run_migration("create_deliveries", :down)
    run_migration("create_mails", :down)
    run_migration("create_messages", :down)
    run_migration("create_messages_recipients", :down)
    run_migration("add_new_mail_count", :down)
    ActiveRecord::Base.connection.drop_table("users")
  end

  def require_generated_models
    models_path = File.expand_path( File.dirname(__FILE__)+"/../generators/mailable/templates/models" )
    require models_path + "/mail"
    require models_path + "/conversation"
    require models_path + "/delivery"
    require models_path + "/message"
  end

  def setup_users
    @tung = User.create!(:name => 'tung')
    @vuon = User.create!(:name => 'vuon')
    @lonna = User.create!(:name => 'lonna')
  end

  def reload_users
    @tung = User.find_by_name('tung')
    @vuon = User.find_by_name('vuon')
    @lonna = User.find_by_name('lonna')
  end
end


