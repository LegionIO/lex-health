require 'legion/data/models/node'

module Legion
  module Extensions
    module Health
      module Runners
        module Health
          def self.update(payload)
            item = Legion::Data::Model::Node.where(name: payload[:hostname]).first
            if item.nil?
              return { success: true, hostname: payload[:hostname] } if insert(payload)
              return { success: false, hostname: payload[:hostname] }
            end

            item.update(active: 1, status: payload[:status], name: payload[:hostname])
            return { success: true, hostname: payload[:hostname] }
          end

          def self.insert(payload)
            insert = {active: 1, status: payload[:status], name: payload[:hostname]}
            Legion::Data::Model::Node.insert(insert)
          end

          def self.delete(payload)
            Legion::Data::Model::Node.where(payload[:key].to_sym == payload[:value]).delete
            return { success: true }
          end
        end
      end
    end
  end
end
