# frozen_string_literal: true

unless defined?(Legion::Extensions::Actors::Every)
  module Legion
    module Extensions
      module Actors
        class Every # rubocop:disable Lint/EmptyClass
        end
      end
    end
  end
end

unless defined?(Legion::Extensions::Actors::Singleton)
  module Legion
    module Extensions
      module Actors
        module Singleton
          def self.included(base)
            base.prepend(ExecutionGuard)
          end

          def singleton_role
            self.class.name&.gsub('::', '_')&.downcase || 'unknown'
          end

          module ExecutionGuard
          end
        end
      end
    end
  end
end

$LOADED_FEATURES << 'legion/extensions/actors/every'
$LOADED_FEATURES << 'legion/extensions/actors/singleton'

require_relative '../../../../../lib/legion/extensions/health/actors/watchdog'

RSpec.describe Legion::Extensions::Health::Actor::Watchdog do
  subject(:actor) { described_class.new }

  describe '#runner_function' do
    it 'returns expire' do
      expect(actor.runner_function).to eq('expire')
    end
  end

  describe '#time' do
    it 'returns 5' do
      expect(actor.time).to eq(5)
    end
  end

  describe '#run_now?' do
    it 'returns true' do
      expect(actor.run_now?).to be true
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe 'singleton enforcement' do
    it 'includes Singleton mixin when available' do
      expect(described_class.ancestors).to include(Legion::Extensions::Actors::Singleton)
    end

    it 'has a singleton_role derived from class name' do
      expect(actor.singleton_role).to eq('legion_extensions_health_actor_watchdog')
    end
  end
end
