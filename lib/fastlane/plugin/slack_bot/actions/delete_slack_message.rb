require 'fastlane/action'
require_relative '../helper/slack_bot_helper'

module Fastlane
  module Actions
    module SharedValues
      DELETE_SLACK_MESSAGE_RESULT = :DELETE_SLACK_MESSAGE_RESULT
    end
    class DeleteSlackMessageAction < Action
      def self.run(options)
        options[:message] = (options[:message].to_s || '').gsub('\n', "\n")

        begin
          require 'excon'

          api_url = "https://slack.com/api/chat.delete"
          headers = { "Content-Type": "application/json", "Authorization": "Bearer #{options[:api_token]}" }
          payload = { channel: options[:channel], ts: options[:ts] }.to_json

          response = Excon.post(api_url, headers: headers, body: payload)
          result = self.formatted_result(response)
        rescue => exception
          UI.error("Exception: #{exception}")
          return nil
        else
          UI.success("Successfully deleted the Slack message!")
          Actions.lane_context[SharedValues::DELETE_SLACK_MESSAGE_RESULT] = result
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
        "Deleate a slack message using time-stamp(ts) value"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_DELETE_SLACK_MESSAGE_BOT_TOKEN",
                                       description: "Slack bot Token",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV["SLACK_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :ts,
                                       env_name: "FL_DELETE_SLACK_MESSAGE_TS",
                                       description: "Timestamp of the message to be deleted",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "FL_DELETE_SLACK_MESSAGE_CHANNEL",
                                       description: "Slack channel_id containing the message to be deleted. i.e C1234567890",
                                       optional: false)
        ]
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'delete_slack_message(
            ts: "1609711037.000100",
            channel: "C1234567890"
          )'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
