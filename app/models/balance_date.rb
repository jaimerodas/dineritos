class BalanceDate < ApplicationRecord
  has_many :balances
  has_many :currency_rates
  has_one :total

  accepts_nested_attributes_for :balances

  def to_param
    date
  end

  def self.id_range
    select(:id)
      .order(date: :desc)
  end

  def self.id_range_from(date, limit: 2)
    id_range.where("date <= ?", date)
      .limit(limit)
  end
end
