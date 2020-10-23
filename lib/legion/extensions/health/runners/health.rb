module Legion::Extensions::Health
  module Runners
    module Health
      include Legion::Extensions::Helpers::Lex

      def update(hostname:, **opts)
        item = Legion::Data::Model::Node[name: hostname]

        return { success: insert(hostname: hostname, **opts), hostname: hostname, **opts } if item.nil?

        if opts.key?(:timestamp) && !item.values[:updated].nil? && item.values[:updated] > Time.parse(opts[:timestamp])
          return { success:    false,
                   reason:     'entry already updated',
                   hostname:   hostname,
                   db_updated: item.values[:updated],
                   **opts }
        end

        {
          success:  item.update(active: 1, status: opts[:status], name: hostname, updated: Sequel::CURRENT_TIMESTAMP),
          hostname: hostname,
          **opts
        }
      end

      def insert(hostname:, status: 'unknown', **opts)
        insert = { active: 1, status: status, name: hostname }
        insert[:datacenter_id] = opts[:datacenter_id] if opts.key? :datacenter_id
        insert[:environment_id] = opts[:environment_id] if opts.key? :environment_id
        insert[:active] = opts[:active] if opts.key? :active

        { success: true, hostname: hostname, node_id: Legion::Data::Model::Node.insert(insert), **insert }
      end

      def delete(node_id:, **_opts)
        Legion::Data::Model::Node[node_id].delete
        { success: true, node_id: node_id }
      end
    end
  end
end
