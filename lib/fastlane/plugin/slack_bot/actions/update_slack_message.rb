require 'fastlane/action'
require_relative '../helper/slack_bot_helper'
require_relative '../helper/slack_bot_attachments_helper'
require_relative '../helper/slack_bot_link_formatter_helper'

module Fastlane
  module Actions
    module SharedValues
      UPDATE_SLACK_MESSAGE_RESULT = :UPDATE_SLACK_MESSAGE_RESULT
    end
    class UpdateSlackMessageAction < Action
      def self.run(options)
        options[:message] = (options[:message].to_s || '').gsub('\n', "\n")
        options[:message] = Helper::SlackBotLinkFormatterHelper.format(options[:message])
        options[:pretext] = options[:pretext].gsub('\n', "\n") unless options[:pretext].nil?
        slack_attachment = Helper::SlackBotAttachmentsHelper.generate_slack_attachments(options)

        begin
          require 'excon'

          api_url = "https://slack.com/api/chat.update"
          headers = { "Content-Type": "application/json", "Authorization": "Bearer #{options[:api_token]}" }
          payload = { channel: options[:channel], attachments: [slack_attachment], ts: options[:ts] }.to_json

          response = Excon.post(api_url, headers: headers, body: payload)
          result = self.formatted_result(response)
        rescue => exception
          UI.error("Exception: #{exception}")
          return nil
        else
          UI.success("Successfully updated the Slack message")
          Actions.lane_context[SharedValues::UPDATE_SLACK_MESSAGE_RESULT] = result
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
        "Update a slack message using time-stamp(ts) value"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_BOT_TOKEN",
                                       description: "Slack bot Token",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV["SLACK_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :ts,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_TS",
                                       description: "Timestamp of the message to be updated",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_CHANNEL",
                                       description: "Slack channel i.e C1234567890",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :pretext,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_PRETEXT",
                                       description: "This is optional text that appears above the message attachment block. This supports the standard Slack markup language",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_MESSAGE",
                                       description: "The message that should be displayed on Slack",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :payload,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_PAYLOAD",
                                       description: "Add additional information to this post. payload must be a hash containing any key with any value",
                                       default_value: {},
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :default_payloads,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_DEFAULT_PAYLOADS",
                                       description: "Remove some of the default payloads. More information about the available payloads on GitHub",
                                       optional: true,
                                       default_value: ['lane', 'test_result', 'git_branch', 'git_author', 'last_git_commit', 'last_git_commit_hash'],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :attachment_properties,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_ATTACHMENT_PROPERTIES",
                                       description: "Merge additional properties in the slack attachment, see https://api.slack.com/docs/attachments",
                                       default_value: {},
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :success,
                                       env_name: "FL_UPDATE_SLACK_MESSAGE_SUCCESS",
                                       description: "Was this successful? (true/false)",
                                       optional: true,
                                       default_value: true,
                                       is_string: false)
        ]
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'update_slack_message(
            ts: "1609711037.000100",
            channel: "C1234567890",
            message: "Update: App successfully released!"
          )',
          'update_slack_message(
            ts: "1609711037.000100",
            channel: "C1234567890",
            message: "Update: App successfully released!",
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
