# Gemfile for Fastlane

source "https://rubygems.org"

gem "fastlane", "~> 2.219"
gem "cocoapods", "~> 1.15"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

