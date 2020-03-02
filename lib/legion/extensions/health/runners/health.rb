module Legion::Extensions::Health
  module Runners
    module Health
      def self.update(hostname:, **opts)
        item = Legion::Data::Model::Node.where(name: hostname).first

        if item.nil?
          return { success: true, hostname: hostname, **opts } if insert(hostname: hostname, **opts)

          return { success: false, hostname: hostname, **opts }
        end

        if opts.key?(:timestamp) && !item.values[:updated].nil? && item.values[:updated] > Time.parse(opts[:timestamp])
          return { success: false, reason: 'entry already updated', hostname: hostname, db_updated: item.values[:updated], **opts }
        end

        item.update(active: 1, status: opts[:status], name: hostname)
        { success: true, hostname: hostname, **opts }
      end

      def self.insert(hostname:, status: 'unknown', **opts)
        insert = { active: 1, status: status, name: hostname }
        insert[:datacenter_id] = opts[:datacenter_id] if opts.key? :datacenter_id
        insert[:environment_id] = opts[:environment_id] if opts.key? :environment_id
        insert[:active] = opts[:active] if opts.key? :active

        { success: true, hostname: hostname, node_id: Legion::Data::Model::Node.insert(insert), **insert }
      end

      def self.delete(node_id:, **_opts)
        # Legion::Data::Model::Node.where(payload[:key].to_sym == payload[:value]).delete
        Legion::Data::Model::Node[node_id].delete
        { success: true, node_id: node_id }
      end
    end
  end
end
