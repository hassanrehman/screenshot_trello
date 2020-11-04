class Reporter

  class CardNotFound < StandardError; end

  #tries to find the best one if already exists .. if it can't be determined, then creates one with this name
  DEFAULT_CHECKLIST_NAME = "Bugs and Finds"

  #options:
  #  card_id: short_id of the card to add bugs in.
  #    TODO: devise other ways to determine which card to use
  #
  def initialize(options={})
    @options = {
        card_id: nil,
        checklist_name: nil,
      }.merge!(options)
  end

  def report
    puts "reporting to:"
    puts "  Board: #{board.name} - Card: #{card.name}"
    puts "  Checklist: #{best_existing_checklist.nil? ? DEFAULT_CHECKLIST_NAME : best_existing_checklist.name}"
    # puts "  Screenshot filename: #{ss_filename = next_screenshot_filename}"
    puts ""

    screenshot_index = max_screenshot_index
    screenshots = []

    if (path = get_screenshot).present?
      screenshots << path
    end

    loop.with_index do |_, i|

      #take message:
      ss_names = screenshots.map.with_index{|_, i| "SS#{screenshot_index + i + 1}" }
      input_message = Readline.readline("\nMessage: #{ss_names.join(" - ").presence&.concat(" - ")}", true)

      if input_message == "cancel" or input_message == "q"
        puts "Cancelling report..."
        break
      elsif input_message == "help" or input_message == "h" or input_message == "?"
        puts "\n\nUse the following commands in message:"
        puts "cancel (q) - cancel the current bug report.."
        puts "screenshot (ss) - to attach an additional screenshot for this item.."
        puts "help (h) - to see this menu..\n\n"

      elsif input_message == "screenshot" or input_message == "ss"
        if (path = get_screenshot).present?
          screenshots << path
        end
      elsif (input_message||"").strip.length > 0
        links = screenshots.map.with_index do |path, i|
            puts "attaching: #{path}"
            ss_filename = "SS#{screenshot_index + i + 1}"
            result = card.add_attachment( File.open(path), "#{ss_filename}.png" )
            path = JSON.parse( result.body )["url"]
            "[#{ss_filename}](#{path})"
          end

        puts "preparing and adding message .. "
        checklist.add_item([links.join(" - "), process_message(input_message)].reject(&:blank?).join(" - "))
        break
      end
    end

    screenshots.each{ |path| FileUtils.rm_f(path) }
    puts "bug report complete.."
  end

  def get_screenshot
    begin
      puts "Starting screencapture in 5 seconds...."
      sleep(1)
      screencapture_path
    rescue Screencapture::Incomplete => e
      puts "screencapture didn't finish .. cancelling report."
      return
    end
  end

  def start_reporting
    loop do
      report

      cmd = Readline.readline("\nPress enter to continue. 'q' or 'exit' to terminate: ", true)
      break if %w(q exit).include?(cmd.downcase)
    end

  end

  def all_usernames
    @_all_usernames ||= board.members.map(&:username)
  end

  def process_message(m)
    message = (m.strip||"")
    message.scan(/\@\w+/).each do |tag|
      found = all_usernames.select{|u| u.include?(tag.downcase.gsub("@", "")) }
      if (username = (found.length == 1 ? found[0] : nil))
        message.gsub!(tag, "@#{username}")
      end
    end
    return message
  end

  def screencapture_path
    Screencapture.new.capture.edit(false).output_path
  end

  def next_screenshot_filename
    "SS#{max_screenshot_index + 1}.png"
  end

  def max_screenshot_index
    card.attachments.map{|a| (a.name||"")[/\Ass\d+/i] }.compact
      .map{|a| a.gsub(/\Ass/i, "").to_i }
      .select{|a| a > 0 }
      .max || 0
  end

  def checklist
    (return @_checklist) if @_checklist

    @_checklist = best_existing_checklist
    @_checklist ||= begin
        @_best_existing_checklist_populated = false
        Trello::Checklist.create(card_id: card.id, name: DEFAULT_CHECKLIST_NAME)
      end

    return checklist
  end

  def best_existing_checklist
    (return @_best_existing_checklist) if @_best_existing_checklist_populated
    @_best_existing_checklist_populated = true

    checklists = card.checklists

    by_keywords = lambda do |keywords|
        keywords = keywords.strip.split(" ").map(&:strip).map(&:downcase)
        checklists.find{|ch| keywords.all?{|keyword| ch.name.downcase.include?(keyword) } }
      end

    @_best_existing_checklist = if checklists.length == 1
        checklists[0]
      elsif @options[:checklist_name].present?
        card.checklists.find do |ch|
          ch.name.downcase.gsub(/\W/, "") == @options[:checklist_name].downcase.gsub(/\W/, "")
        end
      end
    @_best_existing_checklist ||= (by_keywords.("bugs observ") || by_keywords.("bugs finds") || by_keywords.("bugs"))

    return best_existing_checklist
  end

  def card
    (return @_card) if @_card

    if !(card_id = @options[:card_id]).nil?
      _card = Trello::Card.find( @options[:card_id] )
    end
    #TODO: try other ways of determining what cards to use (e.g. cached last used)

    (raise CardNotFound.new) if _card.blank?

    @_card = _card
    return card
  end

  def board
    @_board = card.board
  end


end