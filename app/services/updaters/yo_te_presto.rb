class Updaters::YoTePresto < BaseScraper
  API_URL = "https://api.yotepresto.com/v1/investor/account_statements"

  private

  def login_url
    "https://www.yotepresto.com/login"
  end

  def login
    browser.execute_script(username_script)
    sleep(2)
    browser.form(action: "/sign_in").submit
    sleep(2)
  end

  def raw_value
    data_hash = browser.cookies.to_a
      .filter { |cookie| cookie[:name].start_with?("ytp_") }
      .map { |cookie| [cookie[:name].delete_prefix("ytp_").tr("_", "-"), cookie[:value]] }
      .to_h

    HTTParty.get(API_URL, headers: data_hash.merge({"uid" => username})).dig("valor_cuenta")
  end

  def logout
    browser.execute_script(
      "document.querySelectorAll('[data-testid=\"header-button\"]:last-child')[0].click()"
    )
    browser.button(class: "end__session").click
  end

  def username_script
    <<~JAVASCRIPT
      $('#full_name').append("<h1 class='h3 mt-0' id='name'>CHAFA</h1>");
      $('#your-initials').removeClass('hidden');
      $("[name='sessions[email]']").val('#{username}');
      $('#sessions_password').val('#{password}');
      $('#login-carousel').carousel('next');
      $('#no-register-link').hide();
    JAVASCRIPT
  end
end
