# frozen_string_literal: true

require 'legion/extensions/actors/subscription'

module Legion
  module Extensions
    module Health
      module Actor
        class Health < Legion::Extensions::Actors::Subscription
          def runner_function
            'update'
          end
        end
      end
    end
  end
end
