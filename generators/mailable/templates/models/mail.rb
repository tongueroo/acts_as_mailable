class Mail < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation

  def mark_as_read()
    self.class.update_all ['`read` = ?', true], ['id = ?', self.id]
    sync_new_mail_count
  end
  def mark_as_unread()
    self.class.update_all ['`read` = ?', false], ['id = ?', self.id]
    sync_new_mail_count
  end
  def mark_as_trashed()
    self.class.update_all ['`trashed` = ?', true], ['id = ?', self.id]
    sync_new_mail_count
  end

  def last_delivery()
    self.conversation.last_delivery
  end

  def sync_new_mail_count
    user.sync_new_mail_count
  end
  after_save :sync_new_mail_count

  # we do not want to touch the updated_at timestamps
  def self.mark(ids, mark_type)
    messages = [find(ids)].flatten
    case mark_type
    when "read"
      messages.each {|m| m.mark_as_read }
    when "unread"
      messages.each {|m| m.mark_as_unread }
    when "delete"
      messages.each {|m| m.mark_as_trashed }
    else
      raise "unknown mark_type option #{mark_type}"
    end
    # receiver_id = messages.first.receiver.id
    # sync_new_message_count(receiver_id)
  end
end
