# https://trello.com/app-key
Trello.configure do |config|
  config.developer_public_key = ENV["TRELLO_DEVELOPER_KEY"]  # The "key" from step 1
  config.member_token = ENV["TRELLO_MEMBER_TOKEN"] # The token from step 2.
end
