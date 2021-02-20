require 'fastlane/action'
require_relative '../helper/slack_bot_helper'

module Fastlane
  module Actions
    module SharedValues
      FILE_UPLOAD_TO_SLACK_RESULT = :FILE_UPLOAD_TO_SLACK_RESULT
    end

    class FileUploadToSlackAction < Action
      def self.run(params)
        file_path = params[:file_path]

        if params[:file_name].to_s.empty?
          file_name = File.basename(file_path, ".*") # if file_path = "/path/file_name.jpeg" then will return "file_name"
        else
          file_name = params[:file_name]
        end

        if params[:file_type].to_s.empty?
          file_type = File.extname(file_path)[1..-1] # if file_path = "/path/file_name.jpeg" then will return "jpeg"
        else
          file_type = params[:file_type]
        end

        begin
          require 'faraday'

          api_url = "https://slack.com/api/files.upload"
          conn = Faraday.new(url: api_url) do |faraday|
            faraday.request :multipart
            faraday.request :url_encoded
            faraday.adapter :net_http
          end

          payload = {
            channels: params[:channels],
            file: Faraday::FilePart.new(file_path, file_type),
            filename: file_name,
            filetype: file_type
          }

          payload[:title] = params[:title] unless params[:title].nil?
          payload[:initial_comment] = params[:initial_comment] unless params[:initial_comment].nil?
          payload[:thread_ts] = params[:thread_ts] unless params[:thread_ts].nil?

          response = conn.post do |req|
            req.headers['Authorization'] = "Bearer #{params[:api_token]}"
            req.body = payload
           end

          result = self.formatted_result(response)
        rescue => exception
          UI.error("Exception: #{exception}")
          return nil
        else
          UI.success("Successfully uploaded file to Slack! 🚀")
          Actions.lane_context[SharedValues::FILE_UPLOAD_TO_SLACK_RESULT] = result
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

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Upload a file to slack channel"
      end

      def self.details
        "Upload a file to slack channel or DM to a slack user"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_FILE_UPLOAD_TO_SLACK_BOT_TOKEN",
                                       description: "Slack bot Token",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV["SLACK_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :channels,
                                       env_name: "FL_FETCH_FILES_SLACK_CHANNELS",
                                       description: "Comma-separated list of slack #channel names where the file will be shared",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       env_name: "FL_FILE_UPLOAD_TO_SLACK_FILE_PATH",
                                       description: "relative file path which will upload to slack",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :file_name,
                                       env_name: "FL_FILE_UPLOAD_TO_SLACK_FILE_NAME",
                                       description: "This is optional filename of the file",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :file_type,
                                       env_name: "FL_FILE_UPLOAD_TO_SLACK_FILE_TYPE",
                                       description: "This is optional filetype of the file",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :title,
                                       env_name: "FL_FILE_UPLOAD_TO_SLACK_TITLE",
                                       description: "This is optional Title of file",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :initial_comment,
                                       env_name: "FL_FILE_UPLOAD_TO_SLACK_INITIAL_COMMENT",
                                       description: "This is optional message text introducing the file",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :thread_ts,
                                       env_name: "FL_FILE_UPLOAD_TO_SLACK_THREAD_TS",
                                       description: "Provide another message's ts value to make this message a reply",
                                       is_string: true,
                                       optional: true)
        ]
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'file_upload_to_slack(
            channels: "slack_channel_name",
            file_path: "fastlane/test.png"
          )',
          'file_upload_to_slack(
            title: "This is test title",
            channels: "slack_channel_name1, slack_channel_name2",
            file_path: "fastlane/report.xml"
          )',
          'file_upload_to_slack(
            title: "This is test title",
            initial_comment: "This is test initial comment",
            channels: "slack_channel_name",
            file_path: "fastlane/screenshots.zip"
          )',
          'file_upload_to_slack(
            title: "This is test title", # Optional, uploading file title
            initial_comment: "This is test initial comment",  # Optional, uploading file initial comment
            channels: "slack_channel_name",
            file_path: "fastlane/screenshots.zip",
            thread_ts: thread_ts # Optional, Provide parent slack message `ts` value to upload this file as a reply.
          )'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
