class CreateMails < ActiveRecord::Migration
  def self.up
    create_table :mails do |t|
      t.column :user_id, :integer, :null => false
      t.column :conversation_id, :integer, :null => false
      t.column :read, :boolean, :default => false
      t.column :trashed, :boolean, :default => false
      t.column :mail_type, :string, :limit => 25
      t.timestamps
    end
  end

  def self.down
    drop_table :mails
  end
end
