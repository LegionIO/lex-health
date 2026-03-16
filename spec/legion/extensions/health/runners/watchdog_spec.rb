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

              def publish; end
            end
          end
        end
      end
    end
  end
end

require 'legion/extensions/health/runners/watchdog'

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

  before(:each) { DB[:nodes].delete }

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
end
