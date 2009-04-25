ActsAsMailable
=============

Private messaging plugin for rails.

Install
-------

script/plugin:

<pre>
  script/plugin install http://github.com/tongueroo/acts_as_mailable.git
  script/generate mailable
  rake db:migrate
</pre>

rubygems:

<pre>
# terminal
sudo gem install tongueroo-acts_as_mailable

# environment.rb
config.gem "winton-acts_as_mailable", :lib => "acts_as_mailable", :source => "http://gems.github.com"
</pre>

Models
------

Add <code>acts\_as\_mailable</code> to your user models:

<pre>
class User < ActiveRecord::Base
  acts_as_mailable
end
</pre>

Usage:
----------

<pre>
tung, vuon, lonna = User.all
tung.send_message([vuon, lonna], "whatsup", "whatsup")
c = vuon.mails.first.conversation
vuon.reply(c, tung, "lets go watch a movie")
lonna.reply(c, tung, "lets go get tapioca")
tung.reply(c, vuon, "what time?")
vuon.reply(c, tung, "8pm")
tung.reply(c, lonna, "cant out with vuon")
</pre>


Author:
----------

Tung Nguyen

Thanks to:
  Phil Sergi's actsasmessageable (which a lot of acts_as_mailable is based off)