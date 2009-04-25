class CreateDeliveries < ActiveRecord::Migration
  def self.up
    create_table :deliveries do |t|
      t.column :user_id, :integer, :null => false
      t.column :message_id, :integer, :null => false
      t.column :conversation_id, :integer
      t.column :mail_type, :string, :limit => 25
      t.column :created_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :deliveries
  end
end
