


require 'redmine'
#require 'redmine_show_email'

Redmine::Plugin.register :redmine_show_email do
  name 'Redmine Show email plugin'
  author 'Michiel Hobbelman'
  description 'Show body of html-only-email in Redmine in full layout'
  version '0.0.1'
  url 'https://github.com/mchobbel/redmine_show_email'
  author_url 'mailto:michiel@hobbelman.eu'

  requires_redmine :version_or_higher => '4'



end
