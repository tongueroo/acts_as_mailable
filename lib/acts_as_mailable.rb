module Tongueroo #:nocdoc:
  module Acts #:nocdoc:
    module Mailable #:nocdoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      # declare the class level helper methods which
      # will load the relevant instance methods
      # defined below when invoked
      module ClassMethods
        #enables a class to send and receive messages to members of the same class - currently assumes the model is of class type 'User',
        #some modifications to the migrations and model classes will need to be made to use a model of different type.
        #
        def acts_as_mailable(options = {})
          has_many :deliveries, :order => 'created_at DESC', :dependent => :delete_all
          has_many :mails, :order => 'updated_at DESC', :dependent => :delete_all, :conditions => ["trashed = ?", false]
          has_many :conversations, :through => :mails

          include Tongueroo::Acts::Mailable::InstanceMethods
        end
      end

      # Adds instance methods.
      module InstanceMethods
        #creates new Message and Conversation objects from the given parameters and delivers Mail to each of the recipients' inbox.
        #
        #====params:
        #recipients::
        #     a single user object or array of users to deliver the message to.
        #msg_body::
        #     the body of the message.
        #subject::
        #     the subject of the message, defaults to empty string if not provided.
        #====returns:
        #the sent Delivery.
        #
        #====example:
        #   phil = User.find(3123)
        #   todd = User.find(4141)
        #   phil.send_message(todd, 'whats up for tonight?', 'hey guy')      #sends a Mail message to todd's inbox, and a Mail message to phil's sentbox
        #
        #
        # send_message does this
        # 1. create conversation
        # 2. create message
        # 3. create mail entries
        #      convo.add(recipients, 'inbox')  -> recipients: inboxes
        #      convo.add(sender, 'sentbox')    -> sender: sentboxes
        # 4. create delivery entries
        #      message.deliver('inbox')        -> recipients: flag where it came from, also used to determine if we should email
        #      Deliver.create('sentbox)        -> sender:
        def send_message(opts)
          recipients = opts[:recipients]
          body = opts[:body]
          subject = opts[:subject]

          recipients = [recipients].flatten
          convo = Conversation.create(:subject => subject)
          message = Message.create(:sender => self, :conversation => convo, :body => body, :subject => subject)
          message.recipients << recipients

          convo.add(:sender => self, :recipients => recipients, :mail_type => 'inbox')
          convo.add(:sender => self, :recipients => self, :mail_type => 'sentbox')

          message.deliver('inbox') # TODO: make sure not to deliver emails
          delivery = Delivery.create(:user => self, :message => message, :conversation => convo, :mail_type => 'sentbox')
          return delivery
        end

        # fork_message
        # 1. create conversation
        # 2. create message
        #      ** also copy over messages
        # 3. create mail entries
        #      convo.add(recipients, 'inbox')  -> recipients: inboxes, only 1 recipient
        #      convo.add(sender, 'sentbox')    -> sender: sentboxes
        #      ** new extra mail entries for the user of the forked conversation, forker should also have an inbox entry
        # 4. create delivery entries
        #      ** for each old delivery
        #      **  create delivery but do not delivery email for recipients and sender
        #      message.deliver('inbox')        -> recipients: flag where it came from, also used to determine if we should email
        #      Deliver.create('sentbox)        -> sender:
        def fork_message(opts)
          old_convo = opts[:old_convo]
          recipients = opts[:recipients]
          body = opts[:body]
          subject = opts[:subject]

          recipients = [recipients].flatten
          convo = Conversation.create(:subject => subject)
          message = Message.create(:sender => self, :conversation => convo, :body => body, :subject => subject)
          message.recipients << recipients
          # fork extras
          copy_fork_messages(old_convo, convo, body)

          convo.add(:sender => self, :recipients => recipients, :mail_type => 'inbox')
          convo.add(:sender => self, :recipients => self, :mail_type => 'sentbox')
          # fork extras
          create_fork_mails(convo)

          # fork extras, important to create old deliveries first
          create_fork_deliveries(old_convo, convo)
          message.deliver('inbox')
          delivery = Delivery.create(:user => self, :message => message, :conversation => convo, :mail_type => 'sentbox')
          return delivery
        end
        def copy_fork_messages(old_convo, convo, msg_body)
          subject = old_convo.subject.sub(/^(Re: )?/, "Re: ")
          old_convo.messages.each do |old|
            Message.create(:sender => old.sender, :conversation => convo, :body => msg_body, :subject => subject, :created_at => old.created_at)
          end
        end

        def create_fork_mails(convo)
          convo.add(:sender => self, :recipients => self, :mail_type => 'inbox')
          # convo.add(self, 'inbox')
        end
        def create_fork_deliveries(old_convo, convo)
          old_convo.deliveries.each do |old|
            Delivery.create(:user => old.user, :message => old.message, :conversation => convo, :mail_type => "fork_#{old.mail_type}", :created_at => old.created_at)
          end
        end

        #creates a new Message associated with the given conversation and delivers the reply to each of the given recipients.
        #
        #*explicitly calling this method is rare unless you are replying to a subset of the users involved in the conversation or
        #if you are including someone that is not currently in the conversation.
        #reply_to_sender, reply_to_all, and reply_to_conversation will suffice in most cases.
        #
        #====params:
        #conversation::
        #     the Conversation object that the mail you are responding to belongs.
        #recipients::
        #     a single User object or array of Users to deliver the reply message to.
        #reply_body::
        #     the body of the reply message.
        #subject::
        #     the subject of the message, defaults to 'RE: [original subject]' if one isnt given.
        #====returns:
        #the sent Delivery.
        #
        def reply(conversation, recipients, reply_body, subject = nil)
          return nil if(reply_body.blank?)
          conversation.add(:sender => self, :recipients => recipients, :mail_type => 'inbox')
          subject = subject || conversation.subject.sub(/^(Re: )?/, "Re: ")
          response = Message.create({:sender => self, :conversation => conversation, :body => reply_body, :subject => subject})
          response.recipients = recipients.is_a?(Array) ? recipients : [recipients]
          response.deliver('inbox')
          conversation.add(:sender => self, :recipients => self, :mail_type => 'sentbox')

          Delivery.create(:user => self, :message => response, :conversation => conversation, :mail_type => 'sentbox')
          return response
        end
        #sends a Mail to the sender of the given mail message.
        #
        #====params:
        #conversation::
        #     the Conversation object that you are replying to.
        #reply_body::
        #     the body of the reply message.
        #subject::
        #     the subject of the message, defaults to 'RE: [original subject]' if one isnt given.
        #====returns:
        #the sent Delivery.
        #
        def reply_to_sender(conversation, reply_body, subject = nil)
          return reply(conversation, conversation.originator, reply_body, subject)
        end
        #sends a Mail to all of the recipients of the given mail message (excluding yourself).
        #
        #====params:
        #conversation::
        #     the Conversation object that you are replying to.
        #reply_body::
        #     the body of the reply message.
        #subject::
        #     the subject of the message, defaults to 'RE: [original subject]' if one isnt given.
        #====returns:
        #the sent Delivery.
        #
        def reply_to_all(conversation, reply_body, subject = nil)
          msg = conversation.last_message
          recipients = msg.recipients.clone()
          if(msg.sender != self)
            recipients.delete(self)
            if(!recipients.include?(msg.sender))
              recipients << msg.sender
            end
          end
          return reply(conversation, recipients, reply_body, subject)
        end

        # used to sync a denormalized new_mail_count on the users table
        def sync_new_mail_count
          c = conversations.count(:conditions => ["mails.mail_type = 'inbox' and mails.read = 0"])
          self.class.update_all ["new_mail_count = ?", c], ["id = ?", id]
        end
      end

    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Tongueroo::Acts::Mailable
end