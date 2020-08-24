module Legion::Extensions::Health::Transport::Messages
  class Watchdog < Legion::Transport::Message
    def routing_key
      'health'
    end

    def expiration
      5000
    end

    def validate
      raise 'status should be a string' unless @options[:status].is_a?(String) || @options[:status].nil?

      @valid = true
    end
  end
end
