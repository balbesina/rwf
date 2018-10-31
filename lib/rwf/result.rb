# frozen_string_literal: true

module RWF
  class Result
    attr_reader :state, :error, :ptr

    def initialize(params)
      @params = params
      @state = :initial
      @error = nil
      @ptr = nil
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

    def redirect?
      !ptr.nil?
    end

    def redirect!(ptr)
      @ptr = ptr
      self
    end

    def on_success
      yield if success?
    end

    def on_failure
      yield(error) if failure?
    end

    def state!(value)
      if value.is_a?(Result)
        value.success? ? success! : failure!
        redirect!(value.ptr) if value.redirect?
      else
        value ? success! : failure!
      end
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

  class PtrSuccess < Result
    def initialize(ptr)
      @ptr = ptr
      success!
    end
  end

  class EndSuccess < PtrSuccess
    def initialize
      super(:end)
    end
  end
end
