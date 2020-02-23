class BaseScraper
  def self.current_balance_for(account)
    new(account).run
  end

  def initialize(account)
    @browser = Watir::Browser.new(:chrome, headless: true)
    @username = account.settings.fetch("username")
    @password = account.settings.fetch("password")
  end

  attr_accessor :browser
  attr_reader :username, :password

  def run
    browser.goto login_url
    login
    value = raw_value
    logout
    BigDecimal(value.tr("^0-9.", "")).round(2)
  rescue Watir::Exception::UnknownObjectException => error
    Rails.logger.error error
    browser.screenshot.save "public/errors/#{Time.now.to_i}.png"
    raise error
  ensure
    browser.close
  end

  private

  def login_url
  end

  def login
  end

  def raw_value
  end

  def logout
  end
end
