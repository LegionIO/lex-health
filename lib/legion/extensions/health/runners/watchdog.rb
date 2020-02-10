module Legion::Extensions::Health
  module Runners
    module Watchdog
      def self.expire(**_opts)
        Legion::Data::Model::Node
          .where(status: 'healthy')
          .where(Sequel.lit('updated_at <= DATE_SUB(SYSDATE(), INTERVAL 10 SECOND)'))
          .each do |node|
          Legion::Logging.error node
        end

        { success: true }
      end
    end
  end
end
