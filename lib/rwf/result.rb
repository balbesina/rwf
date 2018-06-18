# frozen_string_literal: true

module RWF
  class Result
    attr_reader :state, :error

    def initialize(params)
      @params = params
      @state = :initial
      @error = nil
    end

    def initial?
      state == :initial
    end

    def success!
      @state = :success
      self
    end

    def success?
      state == :success && error.nil?
    end

    def okish?
      initial? || success?
    end

    def failure!(error = nil)
      @error = error if error
      @state = :failure
      self
    end

    def failure?
      !success?
    end

    def state!(value)
      value ? success! : failure!
    end

    def recover!
      @error = nil
      success!
    end

    def [](key)
      @params[key]
    end

    def to_s
      state.to_s.capitalize
    end
  end
end
