## Fastlane `slack_bot` plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-slack_bot) 
![![License]](https://img.shields.io/badge/license-MIT-green.svg?style=flat) 
[![Gem Version](https://badge.fury.io/rb/fastlane-plugin-slack_bot.svg)](https://badge.fury.io/rb/fastlane-plugin-slack_bot) 
![![RubyGem Download Badge]](https://ruby-gem-downloads-badge.herokuapp.com/fastlane-plugin-slack_bot?type=total) 
[![Twitter: @manish](https://img.shields.io/badge/contact-@manish-blue.svg?style=flat)](https://twitter.com/manish_rathi_)

A fastlane plugin to customize your automation workflow(s) with a **Slack Bot** 🤖 using the [Slack APIs](https://api.slack.com/) 

- [About](#about)
- [Getting Started](#getting-started)
- [Features](#features)
- [Examples](#examples)
- [About Fastlane](#about-fastlane)

## About

A fastlane plugin to post slack message and much more using Slack bot api token. 🚀\
Note: `Fastlane` comes with built-in `slack` action by default, which uses slack webhook url and have webhook limitations.\ 
i.e Listing couple of slack **webhook url** limitations:
- can't post a direct message to a slack user.
- can’t post a message inside a slack thread.
- can’t update a posted slack message.
- can’t list and upload a file inside a slack channel.
- much more, compare to a **Slack Bot** 🤖 using the [Slack APIs](https://api.slack.com/) 

## Getting Started

1. [Generate `Slack token` for `Fastlane` bot](https://slack.com/intl/en-nl/help/articles/115005265703-Create-a-bot-for-your-workspace)
    - From your Slack organization page, go to `Manage` -> `Custom Integrations`
    - Open `Bots`
    - Add Configuration
    - Choose a name for your bot, e.g. `"fastlane"`
    - Save `API Token`

2. Add plugin in your project

```bash
fastlane add_plugin slack_bot
```
If you are using fastlane using Gemfile in your project, add it to your project by running:
```bash
bundle exec fastlane add_plugin slack_bot 
```

3. Use `slack_bot` features inside your lane in `Fastfile` whenever you want.

## Features
Using this `slack_bot` plugin, you can:

- Post a message using [chat.postMessage](https://api.slack.com/methods/chat.postMessage) Slack API
  - [x] Posts a message to a _public_ channel
  - [x] Posts a message to a _private_ channel
  - [x] Posts a message to a _slack user_ (DM)
  - [x] Posts a message inside a _slack thread_ 🧵  (DM)

- Update a message using [chat.update](https://api.slack.com/methods/chat.update) Slack API
  - [x] updates a message in a channel

- List of files in a channel using [files.list](https://api.slack.com/methods/files.list) Slack API
  - [x] A list of files in a channel, It can be filtered and sliced in various ways.

## Examples

In the following example lets send a message to the default slack bot channel.

```ruby
# share on Slack
  post_to_slack(message: "App successfully released!")
```

In the following example lets send a direct message to a slack user that unit tests CI has been failed.

```ruby
# share on Slack
  post_to_slack(
    message: "CI: Your unit tests on #{ENV['CI_COMMIT_REF_NAME']} failed",
    channel: "@SlackUsername" # This can be Slack userID, instead of username i.e @UXXXXX
  )
```

In the following example lets send slack message to `#ios-team` channel for test-flight build.

```ruby
lane :beta do
  gym # Build the app and create .ipa file
  pilot # Upload build to TestFlight
  
  version_number = get_version_number # Get project version
  build_number = get_build_number # Get build number
  beta_release_name = "#{version_number}-#{build_number}-beta-release"
  
  # share on Slack
  post_to_slack(
    message: "Hi team, we have a new test-flight beta build: #{beta_release_name}",
    channel: "#ios-team"
  )
end
```

In the following example lets send slack message with custom payload.

```ruby
# share on Slack
post_to_slack(
  api_token: "xyz", # Preferably configure as ENV['SLACK_API_TOKEN']
  message: "App successfully released!",
  channel: "#channel",  # Optional, by default will post to the default channel configured for the Slack Bot.
  success: true,        # Optional, defaults to true.
  payload: {  # Optional, lets you specify any number of your own Slack attachments.
    "Build Date" => Time.new.to_s,
    "Built by" => "Jenkins",
  },
  default_payloads: [:git_branch, :git_author], # Optional, lets you specify an allowlist of default payloads to include. Pass an empty array to suppress all the default payloads.
        # Don't add this key, or pass nil, if you want all the default payloads. The available default payloads are: `lane`, `test_result`, `git_branch`, `git_author`, `last_git_commit`, `last_git_commit_hash`.
  attachment_properties: { # Optional, lets you specify any other properties available for attachments in the slack API (see https://api.slack.com/docs/attachments).
       # This hash is deep merged with the existing properties set using the other properties above. This allows your own fields properties to be appended to the existing fields that were created using the `payload` property for instance.
    thumb_url: "http://example.com/path/to/thumb.png",
    fields: [{
      title: "My Field",
      value: "My Value",
      short: true
    }]
  }
)
```

## About Fastlane

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
