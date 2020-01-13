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
    puts "  Screenshot filename: #{ss_filename = next_screenshot_filename}"
    puts ""

    #take message:
    begin
      puts "Starting screencapture in 5 seconds...."
      sleep(5)
      attachment_path = screencapture_path
    rescue Screencapture::Incomplete => e
      puts "screencapture didn't finish .. cancelling report."
      return
    end

    ss_basename = File.basename(ss_filename, ".*")
    input_message = Readline.readline("\nMessage: #{ss_basename} - ", true)

    puts "attaching: #{attachment_path}"
    result = card.add_attachment( File.open(attachment_path), ss_filename )
    attachment_remote_path = JSON.parse( result.body )["url"]

    if (input_message||"").strip.length > 0
      puts "preparing and adding message .. "
      checklist.add_item("[#{ss_basename}](#{attachment_remote_path}) - #{process_message(input_message)}")
    end

    FileUtils.rm_f(attachment_path)
    puts "bug report complete.."
    return

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
    max = card.attachments.map{|a| (a.name||"")[/\Ass\d+/i] }.compact
      .map{|a| a.gsub(/\Ass/i, "").to_i }
      .select{|a| a > 0 }
      .max
    "SS#{(max||0)+1}.png"
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