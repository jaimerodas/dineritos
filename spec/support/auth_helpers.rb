module AuthHelpers
  def stub_current_user(user = nil, &block)
    if block
      let(:current_user, &block)
    elsif user
      let(:current_user) { user }
    end

    before do
      allow_any_instance_of(ApplicationController)
        .to receive(:current_user).and_return(current_user)
    end
  end
end

RSpec.configure do |config|
  config.extend AuthHelpers, type: :controller
  config.extend AuthHelpers, type: :request
end
