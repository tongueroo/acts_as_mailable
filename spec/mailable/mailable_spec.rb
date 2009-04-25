require File.dirname(__FILE__) + "/../spec_helper"

describe User do
  before(:each) do
    setup_db
    setup_users
  end
  after(:each) do
    teardown_db
  end

  it "should create mails" do
    Delivery.count.should == 0
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    @tung.deliveries.size.should == 1
    @vuon.deliveries.size.should == 1
    @lonna.deliveries.size.should == 1
    Delivery.count.should == 3
  end
  it "should create conversations" do
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    @tung.conversations.all(:conditions => ['mails.mail_type =  "sentbox"']).size.should == 1
    @tung.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 0
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
    @lonna.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
  end
  it "should not create multiple conversations for same user" do
    Mail.count.should == 0
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    @tung.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 0
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
    @lonna.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
    Mail.count.should == 3

    convo = @vuon.conversations.first
    @vuon.reply(convo, [@tung, @lonna], "reply_body data", "subject data")
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "sentbox"']).size.should == 1
    @tung.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
    @lonna.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
  end
  it "should get conversations from mail" do
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")

    @tung.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 0
    @tung.deliveries.all(:conditions => ["mail_type = 'sentbox'"]).size.should == 1
    @vuon.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 1
    @lonna.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 1
  end

  it "fork message create new thread with and copy over the original conversation deliveries as a fork" do
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    reload_users
    @tung.deliveries.size.should == 1
    @vuon.deliveries.size.should == 1
    @lonna.deliveries.size.should == 1

    @prev_convo = @vuon.conversations.first
    @vuon.send_message(@tung, "forking", "forking", @prev_convo)
    reload_users
    @tung.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 2
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "sentbox"']).size.should == 1

    @tung.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 1
    @tung.deliveries.all(:conditions => ["mail_type = 'fork_sentbox'"]).size.should == 1 # the original mail tung sent
  end

  it "fork message should also create an inbox entry for the forker" do
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    reload_users
    @tung.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 0
    @vuon.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 1

    @prev_convo = @vuon.conversations.first
    @vuon.send_message(@tung, "forking", "forking", @prev_convo)
    reload_users
    @tung.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 1
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "inbox"']).size.should == 2
    @vuon.conversations.all(:conditions => ['mails.mail_type =  "sentbox"']).size.should == 1

    @vuon.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 1
    @tung.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 1
    @tung.deliveries.all(:conditions => ["mail_type = 'fork_sentbox'"]).size.should == 1 # the original mail tung sent
  end

  it "should update the updated_at timestamp for the mail from replies" do
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    mail = @lonna.mails.first
    Mail.update_all ["updated_at = ?", 1.day.ago], ["id = ?", mail.id]
    mail.reload
    timestamp = mail.updated_at

    convo = @vuon.mails.first.conversation
    @vuon.reply(convo, [@tung, @lonna], "reply_body data", "subject data")
    timestamp.should < @lonna.mails.first.updated_at
  end

  it "should send mails"
  it "should send messages into the right mails" do
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    @tung.deliveries.all(:conditions => ["mail_type = 'inbox'"]).size.should == 0
    @tung.deliveries.all(:conditions => ["mail_type = 'sentbox'"]).size.should == 1
  end

  it "should sync users new_mail_count" do
    # new messages
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    reload_users
    @tung.new_mail_count.should == 0
    @vuon.new_mail_count.should == 1
    @lonna.new_mail_count.should == 1

    # mark as read / unread
    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].mark_as_read
    reload_users
    @vuon.new_mail_count.should == 0
    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].mark_as_unread
    reload_users
    @vuon.new_mail_count.should == 1

    # multiple new messages
    @tung.send_message([@vuon, @lonna], "foobar", "foobar")
    reload_users
    @vuon.new_mail_count.should == 2

    # mark as trashed
    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[1].mark_as_trashed
    reload_users
    @vuon.new_mail_count.should == 1
  end
  it "should sync users new_mail_count, do not change it if its the same conversation" do
    # new messages
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    reload_users
    @tung.new_mail_count.should == 0
    @vuon.new_mail_count.should == 1
    @lonna.new_mail_count.should == 1

    # replies
    # should increment for new convos (tung)
    convo = @vuon.mails.all(:conditions => ["mail_type = 'inbox'"]).first.conversation
    mail = convo.last_delivery
    @vuon.reply_to_all(mail, "reply body data", "subject data")
    reload_users
    @tung.new_mail_count.should == 1
    @vuon.new_mail_count.should == 1
    @lonna.new_mail_count.should == 1

    # should not increment
    convo = @lonna.mails.all(:conditions => ["mail_type = 'inbox'"]).first.conversation
    mail = convo.last_delivery
    @lonna.reply_to_all(mail, "reply body data", "subject data")
    reload_users
    @tung.new_mail_count.should == 1
    @vuon.new_mail_count.should == 1
    @lonna.new_mail_count.should == 1

    # after marking as read
    @tung.mails.all(:conditions => ["mail_type = 'inbox'"])[0].mark_as_read
    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].mark_as_read
    @lonna.mails.all(:conditions => ["mail_type = 'inbox'"])[0].mark_as_read
    reload_users
    @tung.new_mail_count.should == 0
    @vuon.new_mail_count.should == 0
    @lonna.new_mail_count.should == 0
    @lonna.reply_to_all(mail, "reply body data", "subject data")
    reload_users
    @tung.new_mail_count.should == 1
    @vuon.new_mail_count.should == 1
    @lonna.new_mail_count.should == 0
  end

  it "should update read state on replies" do
    # new messages
    @tung.send_message([@vuon, @lonna], "whatsup", "whatsup")
    reload_users
    @vuon.new_mail_count.should == 1
    @lonna.new_mail_count.should == 1
    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].read.should be_false
    @lonna.mails.all(:conditions => ["mail_type = 'inbox'"])[0].read.should be_false

    # mark it
    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].mark_as_read
    @lonna.mails.all(:conditions => ["mail_type = 'inbox'"])[0].mark_as_read
    reload_users

    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].read.should be_true
    @lonna.mails.all(:conditions => ["mail_type = 'inbox'"])[0].read.should be_true

    convo = @lonna.mails.all(:conditions => ["mail_type = 'inbox'"]).first.conversation
    mail = convo.last_delivery
    @lonna.reply_to_all(mail, "reply body data", "subject data")
    reload_users
    @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].read.should be_false
  end

  ######################################################################
  # test forking
  it "should have correct number of recipients" do
    @tung.send_message([@vuon], "whatsup", "whatsup")
    reload_users
    convo = @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].conversation
    convo.recipients.clone.size.should == 1

    mail = convo.last_delivery
    @vuon.reply_to_all(mail, "reply body data", "subject data")
    convo = @vuon.mails.all(:conditions => ["mail_type = 'inbox'"])[0].conversation
    convo.recipients.clone.size.should == 2
  end

  # when to fork instead of reply?

  # dont fork
  # regular mesage between 2 people
  # when i send a message, it originally only has 1 recipient
  # upon reply it has 2 recipients
  # reply again will still be only 2 recipients

  # fork
  # when i set a group message to 2 people
  # when i send the message, it originally has 2 recipients right away
  # upon reply to the original sender, it has 3 recipients
  # BUT we want to fork
  # so the number of recipients will always be 2

  # basically if there are at least 2 recipients and both or not me, we should fork
  # forking the message instead of a reply because product wants separate threads for replies in group messages
  #
  # maybe make a method for convo so I can spec it better
  # def fork_instead_of_reply(convo)
  #   recipients = convo.recipients.clone # weird only works if I clone
  #   original_sender = convo.originator
  #   (recipients.size >= 2 and !recipients.include?(original_sender) or
  #     original_sender == current_user)  # original_sender == current_user for case when originator is looking at his own sent message
  # end
end

