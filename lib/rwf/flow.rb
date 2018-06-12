# frozen_string_literal: true

module RWF
  class Flow
    class << self
      def tasks
        @tasks ||= []
      end

      def task(*args)
        task, *options = *args
        task_options = {}
        options.each { |option| task_options.merge!(option) }

        tasks << [task, task_options]
      end

      def cure(*args)
        error(*args, cure: true)
      end

      def error(*args)
        task(*args, type: :error)
      end

      def call(params = {})
        new.(params)
      end
    end

    def call(io_params = {}, params = nil)
      result = Result.new(io_params)
      next_task = nil
      self.class.tasks.each do |task, options = {}|
        next if options[:type] != next_task
        callable = prepare_callable(task)
        task_result = callable.(io_params, params.nil? ? io_params : params)
        next_task = decide(result, task_result, options)

        return result if next_task == :end
      end

      result.initial? ? result.success! : result
    end

    private

    def prepare_callable(task)
      if task.is_a?(Symbol)
        Task.new(method(task))
      elsif task < Flow
        task.new
      elsif task.respond_to?(:call)
        Task.new(task)
      else
        raise Error, 'Not supported task'
      end
    end

    def decide(result, task_result, type: nil, cure: nil, **)
      if type.nil?
        return if task_result.success?
        result.failure!(task_result.error)
      elsif task_result.success? && cure
        result.recover!
        return
      end

      :error
    end
  end
end
