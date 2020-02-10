require 'legion/extensions/actors/every'

module Legion::Extensions::Health::Actor
  class Watchdog < Legion::Extensions::Actors::Every
    def action
      'expire'
    end

    def time
      5
    end
  end
end
