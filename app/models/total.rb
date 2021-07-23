class Total < ApplicationRecord
  belongs_to :user
  monetize :amount_cents

  def self.dates_from(date)
    where("date <= ?", date).order(date: :desc).limit(2).map(&:date)
  end

  def self.next_date_from(date)
    where("date > ?", date).order(date: :asc).limit(1).first&.date
  end

  def self.prev_date_from(date)
    where("date < ?", date).order(date: :desc).limit(1).first&.date
  end
end
