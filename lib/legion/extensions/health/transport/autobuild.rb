require 'legion/extensions/transport/autobuild'

module Legion::Extensions::Health::Transport
  module AutoBuild
    extend Legion::Extensions::Transport::AutoBuild

    def self.e_to_q
      [{
           from:        Legion::Extensions::Heartbeat::Transport::Exchanges::Heartbeat,
           to:          'health',
           routing_key: '#'
       }]
    end
  end
end
