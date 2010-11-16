module MisfitClient
  class Problem < ::ActiveResource::Base
    self.prefix = '/client/'

    def self.element_name
      'problem'
    end

    def self.for(options)
      raise Exception.new("You must specify 'misfit_url' option") if options[:misfit_url].blank?

      Class.new(self).tap do |klass|
        klass.site = options[:misfit_url]
        klass.user = options[:username] if options[:username]
        klass.password = options[:password] if options[:password]
      end
    end
  end
end
