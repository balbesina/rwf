# frozen_string_literal: true

module RWF
  class Task
    def self.call(callable, params = {})
      new(callable).(params)
    end

    attr_reader :result

    def initialize(callable)
      @callable = callable
    end

    def call(io_params = {}, params = nil)
      @result = Result.new(io_params)

      begin
        call_result = @callable.(io_params, params.nil? ? io_params : params)
        @result.state!(call_result)
      rescue StandardError => error
        @result.failure!(error)
      end

      @result
    end
  end
end
