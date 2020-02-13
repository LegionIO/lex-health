require 'legion/transport/messages/node_health'

module Legion::Extensions::Health
  module Runners
    module Watchdog
      def self.expire(**_opts)
        nodes = []
        Legion::Data::Model::Node
          .where(status: 'healthy')
          .where(Sequel.lit('updated <= DATE_SUB(SYSDATE(), INTERVAL 60 SECOND)'))
          .where(active: true)
          .each do |node|
            Legion::Transport::Messages::NodeHealth.new(status:    'unknown',
                                                        node_id:   node.values[:id],
                                                        hostname:  node.values[:name],
                                                        timestamp: node.values[:updated]).publish
            nodes.push(node.values[:id])
          end

        { success: true, count: nodes.count, nodes: nodes }
      end
    end
  end
end
