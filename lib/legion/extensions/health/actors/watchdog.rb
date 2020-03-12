require 'legion/extensions/actors/every'

module Legion::Extensions::Health::Actor
  class Watchdog < Legion::Extensions::Actors::Every
    def runner_function
      'expire'
    end

    def time
      5
    end

    def run_now?
      true
    end

    def use_runner?
      false
    end
  end
end
