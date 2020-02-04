require 'legion/extensions/health/runners/health'

module Legion::Extensions::Health::Actor
  class Health < Legion::Extensions::Actors::Subscription
    def runner_method
      'update'
    end
  end
end
