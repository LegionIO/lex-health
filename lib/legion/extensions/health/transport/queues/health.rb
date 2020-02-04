module Legion
  module Extensions
    module Health
      module Transport
        module Queues
          class Health < Legion::Transport::Queue
            def queue_name
              'node.health'
            end

            def runner_method
              'update'
            end

            def queue_options
              {arguments: { 'x-single-active-consumer': true } }
            end
          end
        end
      end
    end
  end
end
