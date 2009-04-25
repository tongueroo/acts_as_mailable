class Message < ActiveRecord::Base
  #any additional info that needs to be sent in a message (ex. I use these to determine request types)
  serialize :headers

  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_id'
  belongs_to :conversation
  has_and_belongs_to_many :recipients, :class_name => 'User', :join_table => 'messages_recipients', :association_foreign_key => 'recipient_id'

  validates_presence_of :body

  #delivers a message to the the given mail of all recipients, calls the on_deliver_callback if initialized.
  #
  #====params:
  #mail_type:: the mail to send the message to
  #clean:: calls the clean method if this is set (must be implemented)
  #
  def deliver(mail_type, clean = true)
    clean() if clean
    self.save()
    self.recipients.each do |r|
      delivery = Delivery.new(
        :message => self,
        :conversation => self.conversation,
        :mail_type => mail_type.to_s,
        :user => r
      )
      r.deliveries << delivery
    end
  end

  protected
  #[empty method]
  #
  #this gets called when a message is delivered and the clean param is set (default). Implement this if you wish to clean out illegal content such as scripts or anything that will break layout. This is left empty because what is considered illegal content varies.
  def clean()
    #strip all illegal content here. (scripts, shit that will break layout, etc.)
  end

end
