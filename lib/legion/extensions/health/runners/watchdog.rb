require 'legion/transport/messages/node_health'

module Legion::Extensions::Health
  module Runners
    module Watchdog
      include Legion::Extensions::Helpers::Lex

      def expire(expire_time: 60, **_opts)
        nodes = []
        Legion::Data::Model::Node
          .where(status: 'healthy')
          .where(
            Sequel.lit(
              "updated <= DATE_SUB(SYSDATE(), INTERVAL #{expire_time} SECOND)
                  OR
                  (updated is null and created <= DATE_SUB(SYSDATE(), INTERVAL #{expire_time} SECOND))"
            )
          )
          .where(active: true)
          .each do |node|
            Legion::Transport::Messages::NodeHealth.new(status:    'unknown',
                                                        node_id:   node.values[:id],
                                                        hostname:  node.values[:name],
                                                        timestamp: node.values[:updated]).publish
            nodes.push(node.values[:id])
          end
        log.debug("count: #{nodes.count}")
        { success: true, count: nodes.count, nodes: nodes }
      end
    end
  end
end
