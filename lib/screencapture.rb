class Screencapture

  class Incomplete < StandardError; end

  class << self
    def screencapture
      @_screencapture ||= `which screencapture`.strip
    end

    def installed?
      screencapture.present?
    end
  end

  #options:
  #  output_path: +fullpath+ - ~/Desktop/Screenshot <timestamp>.png   #this is default for macs
  #
  def initialize(options={})
    @options = {
        output_path: "#{File.expand_path("~/Desktop")}/#{Time.now.strftime("Screenshot %Y-%m-%d at %H.%M.%S")}.png",
      }.merge!(options)
  end

  def screencapture
    self.class.screencapture
  end

  def osascript
    `which osascript`.strip
  end

  def capture
    cmd = "#{screencapture} -Cs -Jselection \"#{output_path}\""
    puts "Starting mouse UI for screencapture..."
    `#{cmd}`
    (raise Incomplete.new) if !File.exists?(output_path)
    return self
  end

  def edit( wait = true )
    #only run if osascript is available
    if osascript.present?
      cmd = <<-CMD
        open -a Preview \"#{output_path}\";
        #{osascript}
          -e 'tell application "Preview"' 
            -e "activate" 
            -e 'tell application "System Events"' 
              -e 'keystroke "a" using {shift down, command down}' 
            -e "end tell"
          -e "end tell"
      CMD
      cmd = cmd.strip.gsub(/\s+/, " ")
      `#{cmd}`
    end

    if wait
      puts "Starting editing tool .. press any to continue when done.."
      STDIN.getch
    end
    return self
  end

  def output_path
    @options[:output_path]
  end

end