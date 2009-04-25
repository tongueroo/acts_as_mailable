# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts_as_mailable}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tung Nguyen"]
  s.date = %q{2009-04-25}
  s.description = %q{}
  s.email = %q{tongueroo@gmail.com}
  s.extra_rdoc_files = ["README.markdown"]
  s.files = ["acts_as_mailable.gemspec", "generators", "generators/mailable", "generators/mailable/mailable_generator.rb", "generators/mailable/templates", "generators/mailable/templates/INSTALL", "generators/mailable/templates/migrate", "generators/mailable/templates/migrate/add_new_mail_count.rb", "generators/mailable/templates/migrate/create_conversations.rb", "generators/mailable/templates/migrate/create_deliveries.rb", "generators/mailable/templates/migrate/create_mails.rb", "generators/mailable/templates/migrate/create_messages.rb", "generators/mailable/templates/migrate/create_messages_recipients.rb", "generators/mailable/templates/models", "generators/mailable/templates/models/conversation.rb", "generators/mailable/templates/models/delivery.rb", "generators/mailable/templates/models/mail.rb", "generators/mailable/templates/models/message.rb", "init.rb", "install.rb", "lib", "lib/acts_as_mailable.rb", "log", "Rakefile", "README.markdown", "spec", "spec/mailable", "spec/mailable/mailable_spec.rb", "spec/spec_helper.rb", "spec/spec_helpers.rb"]
  s.homepage = %q{http://github.com/tongueroo/acts_as_mailable}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
