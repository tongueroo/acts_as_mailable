module Tongueroo #:nocdoc:
  module Acts #:nocdoc:
    module Mailable #:nodoc
      class Mailbox
        def initialize(user)
          @user = user
        end
  
        def mails
          @user.mails
        end
  
      end # eo Mailbox
    end # eo Mailable
  end # eo Acts
end # eo Tongueroo