# frozen_string_literal: true

require 'spec_helper'
require 'sequel'

DB = Sequel.sqlite unless defined?(DB)

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

unless defined?(Legion::JSON)
  module Legion
    module JSON
      def self.dump(obj)
        require 'json'
        ::JSON.generate(obj)
      end
    end
  end
end

unless defined?(Legion::Data::Model::Node)
  module Legion
    module Data
      module Model
        class Node < Sequel::Model(DB[:nodes]); end
      end
    end
  end
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

require 'legion/extensions/health/runners/health'

RSpec.describe Legion::Extensions::Health::Runners::Health do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Health::Runners::Health

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

  describe '#update with worker health' do
    before(:each) do
      DB[:digital_workers].insert(worker_id: 'w1', name: 'worker-1', health_status: 'unknown',
                                  lifecycle_state: 'active', consent_tier: 'supervised',
                                  trust_score: 0.5, entra_app_id: 'app1', owner_msid: 'ms1',
                                  extension_name: 'lex-test')
      DB[:digital_workers].insert(worker_id: 'w2', name: 'worker-2', health_status: 'unknown',
                                  lifecycle_state: 'active', consent_tier: 'supervised',
                                  trust_score: 0.5, entra_app_id: 'app2', owner_msid: 'ms2',
                                  extension_name: 'lex-test')
    end

    it 'sets reported workers to online' do
      runner.update(hostname: 'node-1', status: 'healthy', hosted_worker_ids: %w[w1 w2])
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:health_status]).to eq('online')
      expect(DB[:digital_workers].where(worker_id: 'w2').first[:health_status]).to eq('online')
    end

    it 'sets last_heartbeat_at on reported workers' do
      runner.update(hostname: 'node-1', status: 'healthy', hosted_worker_ids: ['w1'])
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:last_heartbeat_at]).not_to be_nil
    end

    it 'sets health_node to the reporting hostname' do
      runner.update(hostname: 'node-1', status: 'healthy', hosted_worker_ids: ['w1'])
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:health_node]).to eq('node-1')
    end

    it 'marks workers previously on this node but not in list as unknown' do
      DB[:digital_workers].where(worker_id: 'w1').update(health_status: 'online', health_node: 'node-1')
      runner.update(hostname: 'node-1', status: 'healthy', hosted_worker_ids: ['w2'])
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:health_status]).to eq('unknown')
      expect(DB[:digital_workers].where(worker_id: 'w1').first[:health_node]).to be_nil
    end

    it 'stores metrics JSON on the node record' do
      metrics = { memory_rss_mb: 100, thread_count: 5 }
      runner.update(hostname: 'node-1', status: 'healthy', metrics: metrics)
      node = DB[:nodes].where(name: 'node-1').first
      expect(node[:metrics]).not_to be_nil
    end

    it 'stores hosted_worker_ids JSON on the node record' do
      runner.update(hostname: 'node-1', status: 'healthy', hosted_worker_ids: %w[w1 w2])
      node = DB[:nodes].where(name: 'node-1').first
      expect(node[:hosted_worker_ids]).not_to be_nil
    end

    it 'stores version on the node record' do
      runner.update(hostname: 'node-1', status: 'healthy', version: '1.4.13')
      node = DB[:nodes].where(name: 'node-1').first
      expect(node[:version]).to eq('1.4.13')
    end

    it 'handles missing hosted_worker_ids gracefully' do
      expect { runner.update(hostname: 'node-1', status: 'healthy') }.not_to raise_error
    end

    it 'handles missing DigitalWorker model gracefully' do
      hide_const('Legion::Data::Model::DigitalWorker')
      expect { runner.update(hostname: 'node-1', status: 'healthy', hosted_worker_ids: ['w1']) }.not_to raise_error
    end
  end

  describe '#update insert path' do
    it 'sets active as boolean true on new node' do
      runner.update(hostname: 'new-node', status: 'healthy')
      node = DB[:nodes].where(name: 'new-node').first
      expect(node[:active]).to be(true)
    end
  end

  describe '#update existing node path' do
    before(:each) do
      DB[:nodes].insert(name: 'existing-node', status: 'healthy', active: true,
                        created: Time.now - 60, updated: Time.now - 60)
    end

    it 'updates existing node without error' do
      result = runner.update(hostname: 'existing-node', status: 'healthy')
      expect(result[:success]).to be(true)
    end

    it 'handles nil updated timestamp without crashing' do
      DB[:nodes].where(name: 'existing-node').update(updated: nil)
      expect { runner.update(hostname: 'existing-node', status: 'healthy', timestamp: Time.now.iso8601) }.not_to raise_error
    end
  end

  describe '#delete' do
    it 'deletes an existing node' do
      id = DB[:nodes].insert(name: 'to-delete', status: 'healthy', active: true)
      result = runner.delete(node_id: id)
      expect(result[:success]).to be(true)
      expect(DB[:nodes].where(id: id).first).to be_nil
    end

    it 'returns failure when node does not exist' do
      result = runner.delete(node_id: 999_999)
      expect(result[:success]).to be(false)
      expect(result[:error]).to eq('node not found')
    end
  end

  describe '#insert TOCTOU race' do
    it 'does not crash when insert hits a unique constraint violation' do
      allow(Legion::Data::Model::Node).to receive(:insert)
        .and_raise(Sequel::UniqueConstraintViolation)
      allow(Legion::Data::Model::Node).to receive(:[]).with(name: 'race-node')
                                                      .and_return(Legion::Data::Model::Node.new)
      expect { runner.insert(hostname: 'race-node', status: 'healthy') }.not_to raise_error
    end
  end
end
