# frozen_string_literal: true

require 'time'

module Legion
  module Extensions
    module Health
      module Runners
        module Health
          include Legion::Extensions::Helpers::Lex

          def update(hostname:, **opts)
            item = Legion::Data::Model::Node[name: hostname]

            if item.nil?
              result = insert(hostname: hostname, **opts)
              update_worker_health(hostname: hostname, **opts)
              return { success: result, hostname: hostname, **opts }
            end

            if opts.key?(:timestamp) && item.values[:updated] && item.values[:updated] > Time.parse(opts[:timestamp])
              return { success:    false,
                       reason:     'entry already updated',
                       hostname:   hostname,
                       db_updated: item.values[:updated],
                       **opts }
            end

            update_hash = { active: true, status: opts[:status], name: hostname, updated: Sequel::CURRENT_TIMESTAMP }
            update_hash[:metrics] = json_dump(opts[:metrics]) if opts[:metrics]
            update_hash[:hosted_worker_ids] = json_dump(opts[:hosted_worker_ids]) if opts[:hosted_worker_ids]
            update_hash[:version] = opts[:version] if opts[:version]
            item.update(update_hash)

            update_worker_health(hostname: hostname, **opts)

            { success: true, hostname: hostname, **opts }
          end

          def insert(hostname:, status: 'unknown', **opts)
            insert = { active: true, status: status, name: hostname }
            insert[:datacenter_id] = opts[:datacenter_id] if opts.key? :datacenter_id
            insert[:environment_id] = opts[:environment_id] if opts.key? :environment_id
            insert[:metrics] = json_dump(opts[:metrics]) if opts[:metrics]
            insert[:hosted_worker_ids] = json_dump(opts[:hosted_worker_ids]) if opts[:hosted_worker_ids]
            insert[:version] = opts[:version] if opts[:version]

            node_id = begin
              Legion::Data::Model::Node.insert(insert)
            rescue Sequel::UniqueConstraintViolation
              item = Legion::Data::Model::Node[name: hostname]
              item&.id
            end
            { success: true, hostname: hostname, node_id: node_id, **insert }
          end

          def delete(node_id:, **_opts)
            node = Legion::Data::Model::Node[node_id]
            return { success: false, error: 'node not found', node_id: node_id } if node.nil?

            node.delete
            { success: true, node_id: node_id }
          end

          private

          def update_worker_health(hostname:, **opts)
            return unless defined?(Legion::Data::Model::DigitalWorker)
            return unless opts[:hosted_worker_ids].is_a?(Array)

            now = Time.now
            worker_ids = opts[:hosted_worker_ids]

            worker_ids.each do |wid|
              Legion::Data::Model::DigitalWorker
                .where(worker_id: wid)
                .update(health_status: 'online', last_heartbeat_at: now, health_node: hostname)
            end

            Legion::Data::Model::DigitalWorker
              .where(health_node: hostname, health_status: 'online')
              .exclude(worker_id: worker_ids)
              .each do |worker|
                worker.update(health_status: 'unknown', health_node: nil)
              end
          rescue StandardError => e
            log.warn "worker health update failed: #{e.message}" if respond_to?(:log)
          end
        end
      end
    end
  end
end
