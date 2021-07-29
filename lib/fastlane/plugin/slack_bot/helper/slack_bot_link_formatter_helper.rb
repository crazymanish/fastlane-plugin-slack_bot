require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    # Fastlane is moving away 'slack-notifier' gem, https://github.com/fastlane/fastlane/pull/18512
    # Duplicate of: https://github.com/stevenosloan/slack-notifier/blob/master/lib/slack-notifier/util/link_formatter.rb
    class SlackBotLinkFormatterHelper
        # http://rubular.com/r/19cNXW5qbH
        HTML_PATTERN = %r{
          <a
          (?:.*?)
          href=['"](.+?)['"]
          (?:.*?)>
          (.+?)
          </a>
        }x

        # the path portion of a url can contain these characters
        VALID_PATH_CHARS = '\w\-\.\~\/\?\#\='

        # Attempt at only matching pairs of parens per
        # the markdown spec http://spec.commonmark.org/0.27/#links
        #
        # http://rubular.com/r/y107aevxqT
        MARKDOWN_PATTERN = %r{
            \[ ([^\[\]]*?) \]
            \( ((https?://.*?) | (mailto:.*?)) \)
            (?! [#{VALID_PATH_CHARS}]* \) )
        }x

        class << self
          def format string, opts={}
            SlackBotLinkFormatterHelper.new(string, **opts).formatted
          end
        end

        attr_reader :formats

        def initialize string, opts = {}
          @formats = opts[:formats] || %i[html markdown]
          @orig    = string.respond_to?(:scrub) ? string.scrub : string
        end

        # rubocop:disable Lint/RescueWithoutErrorClass
        def formatted
          return @orig unless @orig.respond_to?(:gsub)

          sub_markdown_links(sub_html_links(@orig))
        rescue => e
          raise e unless RUBY_VERSION < "2.1" && e.message.include?("invalid byte sequence")
          raise e, "#{e.message}. Consider including the 'string-scrub' gem to strip invalid characters"
        end
        # rubocop:enable Lint/RescueWithoutErrorClass

        private

          def sub_html_links string
            return string unless formats.include?(:html)

            string.gsub(HTML_PATTERN) do
              slack_link Regexp.last_match[1], Regexp.last_match[2]
            end
          end

          def sub_markdown_links string
            return string unless formats.include?(:markdown)

            string.gsub(MARKDOWN_PATTERN) do
              slack_link Regexp.last_match[2], Regexp.last_match[1]
            end
          end

          def slack_link link, text=nil
            "<#{link}" \
            "#{text && !text.empty? ? "|#{text}" : ''}" \
            ">"
          end
      end
  end
end
