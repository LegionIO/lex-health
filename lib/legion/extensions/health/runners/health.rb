module Legion::Extensions::Health
  module Runners
    module Health
      def self.update(hostname:, **payload)
        item = Legion::Data::Model::Node.where(name: hostname).first
        if item.nil?
          return { success: true, hostname: payload[:hostname] } if insert(hostname: hostname, **opts)

          return { success: false, hostname: payload[:hostname] }
        end

        item.update(active: 1, status: payload[:status], name: hostname)
        { success: true, hostname: hostname }
      end

      def self.insert(**payload)
        insert = { active: 1, status: payload[:status], name: payload[:hostname] }
        Legion::Data::Model::Node.insert(insert)
      end

      def self.delete(**payload)
        Legion::Data::Model::Node.where(payload[:key].to_sym == payload[:value]).delete
        { success: true }
      end
    end
  end
end
