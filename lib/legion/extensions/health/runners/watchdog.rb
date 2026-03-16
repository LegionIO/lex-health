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
                mark_workers_offline(node_name: node.values[:name])
                nodes.push(node.values[:id])
              end
            log.debug("count: #{nodes.count}")
            { success: true, count: nodes.count, nodes: nodes }
          end

          private

          def mark_workers_offline(node_name:)
            return unless defined?(Legion::Data::Model::DigitalWorker)

            Legion::Data::Model::DigitalWorker
              .where(health_node: node_name, health_status: 'online')
              .each do |worker|
                worker.update(health_status: 'offline')
              end
          rescue StandardError => e
            log.warn "worker offline marking failed: #{e.message}" if respond_to?(:log)
          end
        end
      end
    end
  end
end
