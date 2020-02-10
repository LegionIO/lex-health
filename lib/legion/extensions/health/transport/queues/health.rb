module Legion::Extensions::Health
  module Transport
    module Queues
      class Health < Legion::Transport::Queue
        def queue_name
          'node.health'
        end

        def queue_options
          { arguments: { 'x-single-active-consumer': true }, auto_delete: false }
        end
      end
    end
  end
end
