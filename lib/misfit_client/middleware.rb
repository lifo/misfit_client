module MisfitClient
  class Middleware

    def self.default_ignore_exceptions
      [].tap do |exceptions|
        exceptions << ActiveRecord::RecordNotFound if defined? ActiveRecord
        exceptions << AbstractController::ActionNotFound if defined? AbstractController
        exceptions << ActionController::RoutingError if defined? ActionController
      end
    end

    def initialize(app, options = {})
      @app, @options = app, options
      @options[:ignore_exceptions] ||= self.class.default_ignore_exceptions
    end

    def call(env)
      @app.call(env)
    rescue Exception => exception
      options = (env['exception_notifier.options'] ||= {})
      options.reverse_merge!(@options)

      unless Array.wrap(options[:ignore_exceptions]).include?(exception.class)
        mail = Notifier.exception_notification(env, exception)

        begin
          Problem.for(options).create(:product_identifier => options[:product_identifier], :body => mail.body.encoded, :subject => mail.subject)
        rescue Exception => problem_exception
          Rails.logger.debug "[Misfit] There was an error when trying to submit report to misfit. #{problem_exception.inspect}"
          mail.deliver
        end

        env['exception_notifier.delivered'] = true
      end

      raise exception
    end
  end

end
