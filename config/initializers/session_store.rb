# Be sure to restart your server when you modify this file.

GplusPhotohuntSeverRuby::Application.config.session_store :active_record_store, key: 'JSESSIONID'
ActiveRecord::Base.send(:attr_accessible, :session_id)
