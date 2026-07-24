module UserAuthorization
  extend ActiveSupport::Concern

  private

  def validate_user_account!(user, account)
    raise ArgumentError, "User must be provided" unless user
    raise ArgumentError, "Account must be provided" unless account
    raise ActiveRecord::RecordNotFound, "Account not found for user" unless account.user == user
  end
end
