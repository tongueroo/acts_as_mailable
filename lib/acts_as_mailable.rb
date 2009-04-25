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
        def send_message(recipients, msg_body, subject = '', prev_convo = nil)
          recipients = [recipients].flatten
          convo = Conversation.create({:subject => subject})
          convo.add(recipients, 'inbox')

          # if forking from another conversation, copy over the entries
          if prev_convo
            # only want to create mails for the users included in the forked conversation
            deliveries = prev_convo.deliveries.select do |x|
              self == x.user or recipients.include?(x.user)
            end
            deliveries.each do |delivery|
              attributes = delivery.attributes.clone()
              attributes.delete("id")
              attributes.update("conversation_id" => convo.id, "mail_type" => "fork_#{attributes["mail_type"]}")
              Delivery.create(attributes)
            end
          end

          message = Message.create({:sender => self, :conversation => convo,  :body => msg_body, :subject => subject})
          message.recipients = recipients
          message.deliver('inbox')

          convo.add(self, 'sentbox')
          if prev_convo
            convo.add(self, 'inbox')
          end
          Delivery.create(:user => self, :message => message, :conversation => convo, :mail_type => 'sentbox')
          return message
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
          conversation.add(recipients, 'inbox')
          subject = subject || conversation.subject.sub(/^(Re: )?/, "Re: ")
          response = Message.create({:sender => self, :conversation => conversation, :body => reply_body, :subject => subject})
          response.recipients = recipients.is_a?(Array) ? recipients : [recipients]
          response.deliver('inbox')
          conversation.add(self, 'sentbox')

          Delivery.create(:user => self, :message => response, :conversation => conversation, :mail_type => 'sentbox')
          return response
        end
        #sends a Mail to the sender of the given mail message.
        #
        #====params:
        #mail::
        #     the Mail object that you are replying to.
        #reply_body::
        #     the body of the reply message.
        #subject::
        #     the subject of the message, defaults to 'RE: [original subject]' if one isnt given.
        #====returns:
        #the sent Delivery.
        #
        def reply_to_sender(delivery, reply_body, subject = nil)
          return reply(delivery.conversation, delivery.message.sender, reply_body, subject)
        end
        #sends a Mail to all of the recipients of the given mail message (excluding yourself).
        #
        #====params:
        #delivery::
        #     the Mail object that you are replying to.
        #reply_body::
        #     the body of the reply message.
        #subject::
        #     the subject of the message, defaults to 'RE: [original subject]' if one isnt given.
        #====returns:
        #the sent Delivery.
        #
        def reply_to_all(delivery, reply_body, subject = nil)
          msg = delivery.message
          recipients = msg.recipients.clone()
          if(msg.sender != self)
            recipients.delete(self)
            if(!recipients.include?(msg.sender))
              recipients << msg.sender
            end
          end
          return reply(delivery.conversation, recipients, reply_body, subject)
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