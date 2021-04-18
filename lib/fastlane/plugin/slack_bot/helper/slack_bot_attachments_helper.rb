require 'fastlane_core/ui/ui'
require 'fastlane_core/env'
require_relative 'slack_bot_link_formatter_helper'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class SlackBotAttachmentsHelper
      # class methods that you define here become available in your action
      # as `Helper::SlackBotAttachmentsHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the slack_bot plugin attachments helper!")
      end

      def self.generate_slack_attachments(options)
        color = (options[:success] ? 'good' : 'danger')
        should_add_payload = ->(payload_name) { options[:default_payloads].map(&:to_sym).include?(payload_name.to_sym) }

        slack_attachment = {
          fallback: options[:message],
          text: options[:message],
          pretext: options[:pretext],
          color: color,
          mrkdwn_in: ["pretext", "text", "fields", "message"],
          fields: []
        }

        # custom user payloads
        slack_attachment[:fields] += options[:payload].map do |k, v|
          {
            title: k.to_s,
            value: SlackBotLinkFormatterHelper.format(v.to_s),
            short: false
          }
        end

        # Add the lane to the Slack message
        # This might be nil, if slack is called as "one-off" action
        if should_add_payload[:lane] && Actions.lane_context[Actions::SharedValues::LANE_NAME]
          slack_attachment[:fields] << {
            title: 'Lane',
            value: Actions.lane_context[Actions::SharedValues::LANE_NAME],
            short: true
          }
        end

        # test_result
        if should_add_payload[:test_result]
          slack_attachment[:fields] << {
            title: 'Result',
            value: (options[:success] ? 'Success' : 'Error'),
            short: true
          }
        end

        # git branch
        if Actions.git_branch && should_add_payload[:git_branch]
          slack_attachment[:fields] << {
            title: 'Git Branch',
            value: Actions.git_branch,
            short: true
          }
        end

        # git_author
        if Actions.git_author_email && should_add_payload[:git_author]
          if FastlaneCore::Env.truthy?('FASTLANE_SLACK_HIDE_AUTHOR_ON_SUCCESS') && options[:success]
            # We only show the git author if the build failed
          else
            slack_attachment[:fields] << {
              title: 'Git Author',
              value: Actions.git_author_email,
              short: true
            }
          end
        end

        # last_git_commit
        if Actions.last_git_commit_message && should_add_payload[:last_git_commit]
          slack_attachment[:fields] << {
            title: 'Git Commit',
            value: Actions.last_git_commit_message,
            short: false
          }
        end

        # last_git_commit_hash
        if Actions.last_git_commit_hash(true) && should_add_payload[:last_git_commit_hash]
          slack_attachment[:fields] << {
            title: 'Git Commit Hash',
            value: Actions.last_git_commit_hash(short: true),
            short: false
          }
        end

        # merge additional properties
        deep_merge(slack_attachment, options[:attachment_properties])
      end

      # Adapted from https://stackoverflow.com/a/30225093/158525
      def self.deep_merge(a, b)
        merger = proc do |key, v1, v2|
          Hash === v1 && Hash === v2 ?
                 v1.merge(v2, &merger) : Array === v1 && Array === v2 ?
                   v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2
        end
        a.merge(b, &merger)
      end
    end
  end
end
