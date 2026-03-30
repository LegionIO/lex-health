# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Health
      module Actor
        class Watchdog < Legion::Extensions::Actors::Every # rubocop:disable Legion/Extension/EveryActorRequiresTime
          include Legion::Extensions::Actors::Singleton if defined?(Legion::Extensions::Actors::Singleton)

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
    end
  end
end
