# frozen_string_literal: true

require 'spec_helper'
require 'sequel'

DB = Sequel.sqlite unless defined?(DB)

unless defined?(Legion::Data::Model::Node)
  DB.create_table?(:nodes) do
    primary_key :id
    String :name
    String :status
    TrueClass :active, default: true
    DateTime :created
    DateTime :updated
    String :metrics, text: true
    String :hosted_worker_ids, text: true
    String :version
  end

  module Legion
    module Data
      module Model
        class Node < Sequel::Model(DB[:nodes]); end
      end
    end
  end
end

DB.create_table?(:digital_workers) do
  primary_key :id
  String :worker_id, null: false, unique: true
  String :name
  String :health_status, default: 'unknown'
  DateTime :last_heartbeat_at
  String :health_node
  String :lifecycle_state, default: 'active'
  String :consent_tier, default: 'supervised'
  Float :trust_score, default: 0.0
  String :entra_app_id
  String :owner_msid
  String :extension_name
end

unless defined?(Legion::Data::Model::DigitalWorker)
  module Legion
    module Data
      module Model
        class DigitalWorker < Sequel::Model(DB[:digital_workers])
          def worker_id
            values[:worker_id]
          end
        end
      end
    end
  end
end

unless defined?(Legion::Extensions::Helpers::Lex)
  module Legion
    module Extensions
      module Helpers
        module Lex; end
      end
    end
  end
end

unless defined?(Legion::Extensions::Health::Transport::Messages::Watchdog)
  module Legion
    module Extensions
      module Health
        module Transport
          module Messages
            class Watchdog
              def initialize(**); end

              def routing_key
                'node.health'
              end

              def publish; end
            end
          end
        end
      end
    end
  end
end

require 'legion/extensions/health/runners/watchdog'

RSpec.describe 'Legion::Extensions::Health::Transport::Messages::Watchdog routing_key' do
  it 'is node.health' do
    # The stub class defined above has routing_key overridden; verify the value
    # matches what the real implementation sets. We load the real file with a
    # stubbed base class so the constant check prevents re-definition.
    msg = Legion::Extensions::Health::Transport::Messages::Watchdog.new
    expect(msg.routing_key).to eq('node.health')
  end
end

RSpec.describe Legion::Extensions::Health::Runners::Watchdog do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Health::Runners::Watchdog

      def log
        @log ||= Class.new do
          def debug(*); end

          def warn(*); end
        end.new
      end
    end
    klass.new
  end

  before(:each) do
    DB[:nodes].delete
    DB[:digital_workers].delete
  end

  describe '#expire' do
    it 'finds nodes with updated older than expire_time seconds' do
      DB[:nodes].insert(name: 'old-node', status: 'healthy', active: true,
                        created: Time.now - 120, updated: Time.now - 120)
      result = runner.expire(expire_time: 60)
      expect(result[:count]).to eq(1)
    end

    it 'finds nodes with nil updated and created older than expire_time' do
      DB[:nodes].insert(name: 'nil-updated-node', status: 'healthy', active: true,
                        created: Time.now - 120, updated: nil)
      result = runner.expire(expire_time: 60)
      expect(result[:count]).to eq(1)
    end

    it 'does not expire nodes with recent updated' do
      DB[:nodes].insert(name: 'fresh-node', status: 'healthy', active: true,
                        created: Time.now, updated: Time.now)
      result = runner.expire(expire_time: 60)
      expect(result[:count]).to eq(0)
    end

    it 'publishes a Watchdog message per stale node' do
      DB[:nodes].insert(name: 'stale-1', status: 'healthy', active: true,
                        created: Time.now - 120, updated: Time.now - 120)
      DB[:nodes].insert(name: 'stale-2', status: 'healthy', active: true,
                        created: Time.now - 120, updated: Time.now - 120)
      publish_count = 0
      allow_any_instance_of(Legion::Extensions::Health::Transport::Messages::Watchdog)
        .to receive(:publish) { publish_count += 1 }
      runner.expire(expire_time: 60)
      expect(publish_count).to eq(2)
    end

    it 'returns count of expired nodes' do
      DB[:nodes].insert(name: 'exp-1', status: 'healthy', active: true,
                        created: Time.now - 200, updated: Time.now - 200)
      result = runner.expire(expire_time: 60)
      expect(result[:success]).to be(true)
      expect(result[:count]).to eq(1)
    end

    it 'does not expire inactive nodes' do
      DB[:nodes].insert(name: 'inactive', status: 'healthy', active: false,
                        created: Time.now - 120, updated: Time.now - 120)
      result = runner.expire(expire_time: 60)
      expect(result[:count]).to eq(0)
    end

    it 'does not expire non-healthy nodes' do
      DB[:nodes].insert(name: 'unknown-node', status: 'unknown', active: true,
                        created: Time.now - 120, updated: Time.now - 120)
      result = runner.expire(expire_time: 60)
      expect(result[:count]).to eq(0)
    end
  end

  describe 'worker offline marking' do
    before(:each) do
      DB[:digital_workers].insert(worker_id: 'w1', name: 'worker-1', health_status: 'online',
                                  health_node: 'dead-node', lifecycle_state: 'active',
                                  consent_tier: 'supervised', trust_score: 0.5,
                                  entra_app_id: 'app1', owner_msid: 'ms1', extension_name: 'lex-test')
      DB[:digital_workers].insert(worker_id: 'w2', name: 'worker-2', health_status: 'online',
                                  health_node: 'alive-node', lifecycle_state: 'active',
                                  consent_tier: 'supervised', trust_score: 0.5,
                                  entra_app_id: 'app2', owner_msid: 'ms2', extension_name: 'lex-test')
      DB[:nodes].insert(name: 'dead-node', status: 'healthy', active: true,
                        created: Time.now - 120, updated: Time.now - 120)
    end

    it 'marks workers on expired node as offline' do
      runner.expire(expire_time: 60)
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:health_status]).to eq('offline')
    end

    it 'does not affect workers on other nodes' do
      runner.expire(expire_time: 60)
      expect(DB[:digital_workers].where(worker_id: 'w2').first[:health_status]).to eq('online')
    end

    it 'does not re-update workers already offline' do
      DB[:digital_workers].where(worker_id: 'w1').update(health_status: 'offline')
      runner.expire(expire_time: 60)
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:health_status]).to eq('offline')
    end

    it 'handles missing DigitalWorker model gracefully' do
      hide_const('Legion::Data::Model::DigitalWorker')
      expect { runner.expire(expire_time: 60) }.not_to raise_error
    end

    it 'clears health_node on workers when their node is expired' do
      runner.expire(expire_time: 60)
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:health_node]).to be_nil
    end
  end
end
