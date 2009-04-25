class AddNewMailCount < ActiveRecord::Migration
  def self.up
    add_column :users, :new_mail_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :new_mail_count
  end
end
