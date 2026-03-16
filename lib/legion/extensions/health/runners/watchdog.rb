# frozen_string_literal: true

module Legion
  module Extensions
    module Health
      module Runners
        module Watchdog
          include Legion::Extensions::Helpers::Lex

          def expire(expire_time: 60, **_opts)
            cutoff = Time.now - expire_time
            nodes = []
            Legion::Data::Model::Node
              .where(status: 'healthy')
              .where(active: true)
              .where { (updated <= cutoff) | ((updated =~ nil) & (created <= cutoff)) }
              .each do |node|
                Legion::Extensions::Health::Transport::Messages::Watchdog.new(
                  status:    'unknown',
                  node_id:   node.values[:id],
                  hostname:  node.values[:name],
                  timestamp: node.values[:updated]
                ).publish
                nodes.push(node.values[:id])
              end
            log.debug("count: #{nodes.count}")
            { success: true, count: nodes.count, nodes: nodes }
          end
        end
      end
    end
  end
end
