require 'fastlane/action'
require_relative '../helper/slack_bot_helper'

module Fastlane
  module Actions
    module SharedValues
      FETCH_FILES_SLACK_RESULT = :FETCH_FILES_SLACK_RESULT
    end
    class FetchFilesSlackAction < Action
      def self.run(options)
        require 'excon'
        require 'json'

        api_url = "https://slack.com/api/files.list"
        headers = { "Content-Type": "application/json", "Authorization": "Bearer #{options[:api_token]}" }
        query = { channel: options[:channel], count: options[:count], page: options[:page] }

        response =  Excon.get(api_url, headers: headers, query: query)
        status_code = response[:status]
        UI.user_error!("Response body is nil, status code: #{status_code} 💥") if response.body.nil?

        result = {
          status: status_code,
          body: response.body,
          json: JSON.parse(response.body)
        }

        Actions.lane_context[SharedValues::FETCH_FILES_SLACK_RESULT] = result
        return result
      end

      def self.description
        "List files of any #channel using Slack bot `files.list` api."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_FETCH_FILES_SLACK_BOT_TOKEN",
                                       description: "Slack bot Token",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV["SLACK_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "FL_FETCH_FILES_SLACK_CHANNEL",
                                       description: "slack #channel ID",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :count,
                                       env_name: "FL_FETCH_FILES_SLACK_COUNT",
                                       description: "Number of items to return per page, default value: 100",
                                       default_value: "100",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :page,
                                       env_name: "FL_FETCH_FILES_SLACK_PAGE",
                                       description: "Page number of results to return, default value: 1",
                                       default_value: "1",
                                       optional: true)
        ]
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'fetch_files_slack(channel: "CHXYMXXXX")',
          'fetch_files_slack(channel: "CHXYMXXXX", count: "10")',
          'fetch_files_slack(channel: "CHXYMXXXX", count: "10", page: "2")'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
