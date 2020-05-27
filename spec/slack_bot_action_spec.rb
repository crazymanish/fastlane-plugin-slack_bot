describe Fastlane::Actions::SlackBotAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The slack_bot plugin is working!")

      Fastlane::Actions::SlackBotAction.run(nil)
    end
  end
end
