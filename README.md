# Screenshot Trello

This tool helps process bug reports on Trello in a specific way. The process flow goes as follows:

1. Shows the user which card and checklist is the bug report going in
2. Shows the user the screenshot file name (SSx.png) that the attachment will go as
3. Opens the screenshot generating tool and saves the file (temporarily) on ~/Desktop
4. Allows the user to attach a message to it and/or tag certain people to it
5. Posts the bug requests and waits for user to indicate the repeat of the process

## Prerequisites

### Screencapture Terminal Utility
This is tested on MAC systems only. It uses terminal utility called `screencapture`. Make the the following works:
```
➜  screenshot_trello git:(master) which screencapture
/usr/sbin/screencapture      #any similar path would be ok .. as long as there is one
```

### Ruby 2.5.7
Recommended usage via rvm (.ruby-version) file is present.

### Not required, but good to have
System uses osascript utility to open the editing tool once the screenshot is taken, in case we need to annotate anything. This can be done manually if the osascript doesn't exist or fails.

### Trello keys
Use `https://trello.com/app-key` path to generate developer_key and member_token
Create a file called .env in the root and add contents like this:
```
TRELLO_DEVELOPER_KEY=<developer_key>
TRELLO_MEMBER_TOKEN=<member_token>
```

## Setup
Clone the repository and run bundle.
run `chmod +x ./run` to make sure run is a bash executable file

## Usage
Every screenshot goes into a checklist of a card. Cards are identified by their card_id. Ever trello card has the adderss in the format:
`https://trello.com/c/<card_id>/<card_slug>`

Example 1: Post bug report on a particular card and checklist
`./run <card_id> "Checklist name"`

Example 2: Post bug report on a particular card (and identify checklist on your own)
`./run <card_id>`
If there is no checklist in the card, it is created by with the name `Bugs and Finds`
If there is only one checklist in the card, it is used.
If there are multiple checklists in the card, the one containing keyswords like bugs and finds, bugs and observations and such is taken by default. If none of those kinds are found, new one is created by the name `Bugs and Finds`






