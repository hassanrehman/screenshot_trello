require 'trello'
require 'readline'
require 'fileutils'
require 'dotenv'

ROOT_PATH = File.dirname( __FILE__ )
Dotenv.load

{
  config: %w(trello),
  lib: %w(screencapture reporter),
}.each{|d, files| files.each{|f| require( "#{ROOT_PATH}/#{d}/#{f}.rb" ) } }

args = $*

unless Screencapture.installed?
  puts "\n\nFATAL ERROR: could not find screencapture via: `which screencapture`\n\n"
  exit
end

reporter = Reporter.new({ card_id: args[0], checklist_name: args[1] })

begin
  reporter.start_reporting

rescue Reporter::CardNotFound => e
  puts "Unable to find appropriate card to report on"
rescue Trello::Error => e
  if e.message.include?("card not found")
    puts "Unable to find appropriate card to report on"
  else
    raise e
  end
rescue Interrupt => e
  puts "\nInterrupted by user.."
end




