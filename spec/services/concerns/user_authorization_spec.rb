# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserAuthorization do
  fixtures :users

  let(:user) { users(:test_user) }
  let(:other_user) { users(:test_user_2) }
  let(:account) { user.accounts.create!(name: "Test Account", currency: "MXN") }

  let(:subject_class) do
    Class.new do
      include UserAuthorization

      def call(user, account) = validate_user_account!(user, account)
    end
  end

  subject(:validator) { subject_class.new }

  describe "#validate_user_account!" do
    it "passes when the account belongs to the user" do
      expect { validator.call(user, account) }.not_to raise_error
    end

    it "raises when no user is given" do
      expect { validator.call(nil, account) }
        .to raise_error(ArgumentError, "User must be provided")
    end

    it "raises when no account is given" do
      expect { validator.call(user, nil) }
        .to raise_error(ArgumentError, "Account must be provided")
    end

    it "raises when the account belongs to another user" do
      expect { validator.call(other_user, account) }
        .to raise_error(ActiveRecord::RecordNotFound, "Account not found for user")
    end
  end
end
