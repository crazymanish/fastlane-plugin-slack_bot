require 'fastlane/action'
require_relative '../helper/slack_bot_helper'
require_relative '../helper/slack_bot_attachments_helper'
require_relative '../helper/slack_bot_link_formatter_helper'

module Fastlane
  module Actions
    module SharedValues
      POST_TO_SLACK_RESULT = :POST_TO_SLACK_RESULT
    end

    class PostToSlackAction < Action
      def self.run(options)
        options[:message] = (options[:message].to_s || '').gsub('\n', "\n")
        options[:message] = Helper::SlackBotLinkFormatterHelper.format(options[:message])
        options[:pretext] = options[:pretext].gsub('\n', "\n") unless options[:pretext].nil?

        if options[:channel].to_s.length > 0
          slack_channel = options[:channel]
          slack_channel = ('#' + options[:channel]) unless ['#', 'C', '@'].include?(slack_channel[0]) # Add prefix(#) by default, if needed
        end

        slack_attachment = Helper::SlackBotAttachmentsHelper.generate_slack_attachments(options)
        bot_username = options[:username]
        bot_icon_url = options[:icon_url]

        begin
          require 'excon'

          api_url = "https://slack.com/api/chat.postMessage"
          headers = {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": "Bearer #{options[:api_token]}"
          }
          payload = {
            channel: slack_channel,
            username: bot_username,
            icon_url: bot_icon_url,
            attachments: [slack_attachment]
          }
          payload[:as_user] = options[:as_user] if options[:as_user] # default is false
          payload[:reply_broadcast] = options[:reply_broadcast] if options[:reply_broadcast] # default is false
          payload[:thread_ts] = options[:thread_ts] unless options[:thread_ts].nil?
          payload = payload.to_json

          response = Excon.post(api_url, headers: headers, body: payload, omit_default_port: true)
          result = self.formatted_result(response)
        rescue => exception
          UI.error("Exception: #{exception}")
          return nil
        else
          UI.success("Successfully sent Slack notification")
          Actions.lane_context[SharedValues::POST_TO_SLACK_RESULT] = result
          return result
        end
      end

      def self.formatted_result(response)
        result = {
          status: response[:status],
          body: response.body || "",
          json: self.parse_json(response.body) || {}
        }
      end

      def self.parse_json(value)
        require 'json'

        JSON.parse(value)
      rescue JSON::ParserError
        nil
      end

      def self.description
        "Post a slack message"
      end

      def self.details
        "Post a slack message to any #channel/@user using Slack bot chat postMessage api."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_POST_TO_SLACK_BOT_TOKEN",
                                       description: "Slack bot Token",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV["SLACK_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "FL_POST_TO_SLACK_CHANNEL",
                                       description: "#channel or @username",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_SLACK_USERNAME",
                                       description: "Overrides the bot's username (chat:write.customize scope required)",
                                       default_value: "fastlane",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :icon_url,
                                       env_name: "FL_SLACK_ICON_URL",
                                       description: "Overrides the bot's image (chat:write.customize scope required)",
                                       default_value: "https://fastlane.tools/assets/img/fastlane_icon.png",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :as_user,
                                       env_name: "FL_POST_TO_SLACK_AS_USER",
                                       description: "Pass true to post the message as the authed user. Defaults to false",
                                       optional: true,
                                       default_value: false,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :pretext,
                                       env_name: "FL_POST_TO_SLACK_PRETEXT",
                                       description: "This is optional text that appears above the message attachment block. This supports the standard Slack markup language",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_POST_TO_SLACK_MESSAGE",
                                       description: "The message that should be displayed on Slack",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :payload,
                                       env_name: "FL_POST_TO_SLACK_PAYLOAD",
                                       description: "Add additional information to this post. payload must be a hash containing any key with any value",
                                       default_value: {},
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :default_payloads,
                                       env_name: "FL_POST_TO_SLACK_DEFAULT_PAYLOADS",
                                       description: "Remove some of the default payloads. More information about the available payloads on GitHub",
                                       optional: true,
                                       default_value: ['lane', 'test_result', 'git_branch', 'git_author', 'last_git_commit', 'last_git_commit_hash'],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :attachment_properties,
                                       env_name: "FL_POST_TO_SLACK_ATTACHMENT_PROPERTIES",
                                       description: "Merge additional properties in the slack attachment, see https://api.slack.com/docs/attachments",
                                       default_value: {},
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :success,
                                       env_name: "FL_POST_TO_SLACK_SUCCESS",
                                       description: "Was this successful? (true/false)",
                                       optional: true,
                                       default_value: true,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :no_color,
                                       env_name: "FL_POST_TO_SLACK_NO_COLOR",
                                       description: "Removes the border on the left side. If true, :success option will be ignored",
                                       optional: true,
                                       default_value: false,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :thread_ts,
                                       env_name: "FL_POST_TO_SLACK_THREAD_TS",
                                       description: "Provide another message's ts value to make this message a reply",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :reply_broadcast,
                                       env_name: "FL_POST_TO_SLACK_REPLY_BROADCAST",
                                       description: "Used in conjunction with thread_ts and indicates whether reply should be made visible to everyone in the channel or conversation. Defaults to false",
                                       optional: true,
                                       default_value: false,
                                       is_string: false)
        ]
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'post_to_slack(message: "App successfully released!")',
          'post_to_slack(
            message: "App successfully released!",
            channel: "#channel",  # Optional, by default will post to the default channel configured for the POST URL.
            success: true,        # Optional, defaults to true.
            payload: {            # Optional, lets you specify any number of your own Slack attachments.
              "Build Date" => Time.new.to_s,
              "Built by" => "Jenkins",
            },
            default_payloads: [:git_branch, :git_author], # Optional, lets you specify a whitelist of default payloads to include. Pass an empty array to suppress all the default payloads.
                                                          # Don\'t add this key, or pass nil, if you want all the default payloads. The available default payloads are: `lane`, `test_result`, `git_branch`, `git_author`, `last_git_commit`, `last_git_commit_hash`.
            attachment_properties: { # Optional, lets you specify any other properties available for attachments in the slack API (see https://api.slack.com/docs/attachments).
                                     # This hash is deep merged with the existing properties set using the other properties above. This allows your own fields properties to be appended to the existing fields that were created using the `payload` property for instance.
              thumb_url: "http://example.com/path/to/thumb.png",
              fields: [{
                title: "My Field",
                value: "My Value",
                short: true
              }]
            }
          )'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
