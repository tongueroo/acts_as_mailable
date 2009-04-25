class CreateMessagesRecipients < ActiveRecord::Migration
  def self.up
    create_table :messages_recipients, :id => false do |t|
      t.column :message_id, :integer, :null => false
      t.column :recipient_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :messages_recipients
  end
end
