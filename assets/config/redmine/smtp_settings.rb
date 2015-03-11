if Rails.env.production?
  ActionMailer::Base.delivery_method = :{{SMTP_METHOD}}
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.{{SMTP_METHOD}}_settings = {
    :address              => "{{SMTP_HOST}}",
    :port                 => {{SMTP_PORT}},
    :domain               => "{{SMTP_DOMAIN}}",
    :user_name            => "{{SMTP_USER}}",
    :password             => "{{SMTP_PASS}}",
    :authentication       => {{SMTP_AUTHENTICATION}},
    :openssl_verify_mode  => "{{SMTP_OPENSSL_VERIFY_MODE}}",
    :enable_starttls_auto => {{SMTP_STARTTLS}}
  }
end
