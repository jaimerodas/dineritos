class BalanceDate < ApplicationRecord
  belongs_to :user

  def to_param
    date
  end

  def self.id_range
    select(:id)
      .order(date: :desc)
  end

  def amount
    return unless amount_cents
    Money.new(amount_cents)
  end
end
