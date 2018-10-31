# frozen_string_literal: true

module RWF
  class Flow
    ALLOWED_OPTIONS = %i[type cure ptr on_success on_error].freeze

    class << self
      def tasks
        @tasks ||= []
      end

      def task(*args)
        task, *options = *args
        task_options = {}
        options.each { |option| task_options.merge!(option) }
        task_options[:ptr] ||= task if task.is_a?(Symbol)

        extra_options = task_options.keys - ALLOWED_OPTIONS
        raise ConfigError, "Unknown task option(s): #{extra_options.join(',')}." unless extra_options.empty?

        tasks << [task, task_options]
      end

      def cure(*args)
        error(*args, cure: true)
      end

      def error(*args)
        task(*args, type: :error)
      end

      def call(io_params = {}, params = nil)
        new.(io_params, params)
      end
    end

    def tasks
      self.class.tasks
    end

    def call(io_params = {}, params = nil)
      result = Result.new(io_params)
      next_type = nil
      next_ptr = nil
      next_index = 0

      while next_index < tasks.size
        task, options = tasks[next_index]

        if options[:type] == next_type || next_ptr
          next_type, next_ptr = execute_task(result, task, options, io_params, params)
          break if next_ptr == :end
        end

        next_index = decide_index(next_index, next_ptr)
      end

      result.initial? ? result.success! : result
    end

    private

    def execute_task(result, task, options, io_params, params)
      callable = prepare_callable(task)
      task_result = callable.(io_params, params.nil? ? io_params : params)
      next_type = decide_type(result, task_result, options)
      next_ptr = task_result.redirect? ? task_result.ptr : decide_ptr(task_result, options)

      [next_type, next_ptr]
    end

    def prepare_callable(task)
      if task.is_a?(Symbol)
        Task.new(method(task))
      elsif task.respond_to?(:<) && task < Flow
        task
      elsif task.respond_to?(:call)
        Task.new(task)
      else
        raise Error, 'Not supported task.'
      end
    end

    def decide_type(result, task_result, cure: nil, **)
      if result.okish?
        return if task_result.success?
        result.failure!(task_result.error)
      elsif task_result.success? && cure
        result.recover!
        return
      end

      :error
    end

    def decide_ptr(task_result, on_success: nil, on_error: nil, **)
      if on_success && task_result.success?
        on_success
      elsif on_error && task_result.failure?
        on_error
      end
    end

    def decide_index(next_index, next_ptr)
      if next_ptr
        find_index(next_ptr)
      else
        next_index + 1
      end
    end

    def find_index(next_ptr)
      tasks.index { |_task, ptr: nil, **| ptr == next_ptr } ||
        raise(ConfigError, "Task with pointer '#{next_ptr}' not found.")
    end
  end
end
