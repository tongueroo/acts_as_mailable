require 'rubygems'
require 'spec'
RAILS_ENV = 'test'

# set up database and models
require File.dirname(__FILE__) + "/spec_helpers"
include SpecHelperFunctions
setup_db_connection
require_generated_models

# load plugins dependencies
$:.unshift File.dirname(__FILE__) + '/../vendor/plugins/will_paginate/lib'
require 'will_paginate'

# load the plugin
$:.unshift File.dirname(__FILE__) + '/../lib'
require File.dirname(__FILE__) + '/../init'

# mixin the plugin
class User < ActiveRecord::Base
  acts_as_mailable
end


Spec::Runner.configure do |config|
end
