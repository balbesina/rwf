# frozen_string_literal: true

module FlowSpec
  RSpec.describe RWF::Flow, type: :model do
    describe '::tasks' do
      it 'is not nil' do
        expect(RWF::Flow.tasks).not_to be_nil
      end

      it 'is empty' do
        expect(RWF::Flow.tasks).to be_empty
      end

      class NestedFlow < RWF::Flow
        task :method_task
        task ->(*) { true }

        def method_task(*)
          true
        end
      end

      class SomeCallable
        def self.call(*)
          true
        end
      end

      class TasksFlow < RWF::Flow
        task NestedFlow
        task SomeCallable
      end

      it 'supports methods, procs, nested flows and callables' do
        expect(TasksFlow.().success?).to be true
      end

      context 'when task is unknown' do
        class StrangeFlow < RWF::Flow
          task Object.new
        end

        it 'raises error' do
          expect { StrangeFlow.() }.to raise_error RWF::Error, 'Not supported task.'
        end
      end
    end

    context 'when descendant initialized' do
      class DescFlow < RWF::Flow
        task :some_task
      end

      module Nested; end
      class Nested::DescFlow < RWF::Flow
        task :task1
        task :task2
        task :task3
      end

      module NestedAgain
        class DescFlow < RWF::Flow
          task :task1
          task :task2
        end
      end

      class DescDescFlow < NestedAgain::DescFlow
        task :single
      end

      shared_examples 'task mix' do |flow_class, task_count|
        it 'is not mixing tasks' do
          expect(flow_class.tasks.size).to eq task_count
        end
      end

      include_examples 'task mix', DescDescFlow, 1
      include_examples 'task mix', NestedAgain::DescFlow, 2
      include_examples 'task mix', Nested::DescFlow, 3
      include_examples 'task mix', DescFlow, 1
      include_examples 'task mix', RWF::Flow, 0
    end

    describe '#call' do
      it 'is success without tasks' do
        expect(RWF::Flow.().success?).to be true
      end

      context 'when task result' do
        class TestFlow < RWF::Flow
          task :test_task

          def test_task(_params, test_result:, **)
            test_result
          end
        end

        shared_examples 'result.success?' do |test_result, success|
          it 'is success for thruthy' do
            expect(TestFlow.(test_result: test_result).success?).to be success
          end
        end

        include_examples 'result.success?', true, true
        include_examples 'result.success?', [], true
        include_examples 'result.success?', 0, true
        include_examples 'result.success?', false, false
        include_examples 'result.success?', nil, false
      end

      context 'when task result' do
        class AbcFlow < RWF::Flow
          task :task1
          task :task2

          def task1(params, a:, b:, **)
            params[:ab] = a + b
          end

          def task2(params, ab:, c:, **)
            params[:abc] = ab * c
          end
        end

        let(:result) { AbcFlow.(a: 13, b: 8, c: 2) }

        it 'shares params between tasks' do
          expect(result.success?).to be true
        end

        it 'returns to result' do
          expect(result[:abc]).to eq 42
        end
      end

      context 'when cure' do
        class ErrorFlow < RWF::Flow
          task :task_that_fails
          task :unreachable_task
          error :error_task
          task :other_unreachable_task

          def task_that_fails(*)
            raise StandardError
          end

          def unreachable_task(params, *)
            params[:output] = 'you should not see me'
          end

          def error_task(params, *)
            params[:error] = 'error task was called'
          end

          def other_unreachable_task(params, *)
            params[:other_output] = 'you should not see me, either'
          end
        end

        let(:result) { ErrorFlow.() }

        it 'is failure' do
          expect(result.failure?).to be true
        end

        it 'is not running task after failed one' do
          expect(result[:output]).to be_nil
        end

        it 'is running error task' do
          expect(result[:error]).to eq 'error task was called'
        end

        it 'is not running task after error task' do
          expect(result[:other_output]).to be_nil
        end
      end

      context 'when cure' do
        class CureFlow < RWF::Flow
          task :task_that_fails
          task :unreachable_task
          cure :cure_task
          task :available_after_fail

          def task_that_fails(*)
            false
          end

          def unreachable_task(params, *)
            params[:output] = 'you should not see me'
          end

          def cure_task(params, should_cure:, **)
            params[:error] = 'cure task was called'
            should_cure
          end

          def available_after_fail(params, *)
            params[:other_output] = 'you should see me if cured'
          end
        end

        let(:should_cure) { true }
        let(:result) { CureFlow.(should_cure: should_cure) }

        it 'is success' do
          expect(result.success?).to be true
        end

        it 'is not running task after failed one' do
          expect(result[:output]).to be_nil
        end

        it 'is running cure task' do
          expect(result[:error]).to eq 'cure task was called'
        end

        it 'is running task after cure applied' do
          expect(result[:other_output]).to eq 'you should see me if cured'
        end

        context 'when medicine does not help' do
          let(:should_cure) { false }

          it 'is failure' do
            expect(result.failure?).to be true
          end

          it 'is not running task after failed one' do
            expect(result[:output]).to be_nil
          end

          it 'is running cure task' do
            expect(result[:error]).to eq 'cure task was called'
          end

          it 'is not running task after failed cure task' do
            expect(result[:other_output]).to be_nil
          end
        end
      end
    end

    context 'when task changes flow order' do
      class ChangeFlow < RWF::Flow
        task :task1, on_success: :end, on_error: :task3
        task :unreachable_task
        task :task3, on_success: :some_ptr
        task :task4, ptr: :some_ptr, on_success: :missing_ptr

        def task1(_params, task1_returns:, **)
          task1_returns
        end

        def unreachable_task(params, *)
          params[:output] = 'you should not see me'
          false
        end

        def task3(params, *)
          params[:task3_result] = 'task3 was called'
        end

        def task4(params, task4_returns: false, **)
          params[:task4_result] = 'task4 was called'
          task4_returns
        end
      end

      let(:task1_returns) { true }
      let(:task4_returns) { false }
      let(:result) { ChangeFlow.(task1_returns: task1_returns, task4_returns: task4_returns) }

      it 'is success' do
        expect(result.success?).to be true
      end

      it 'skips unreachable task' do
        expect(result[:output]).to be_nil
      end

      context 'when task error' do
        let(:task1_returns) { false }

        it 'follows the pointer to task3' do
          expect(result[:task3_result]).to eq 'task3 was called'
        end

        it 'supports named pointers to any task' do
          expect(result[:task4_result]).to eq 'task4 was called'
        end

        context 'when pointer to missing task' do
          let(:task4_returns) { true }

          it 'raises when task pointer was not found' do
            expect { result.success? }.to raise_error RWF::ConfigError, 'Task with pointer \'missing_ptr\' not found.'
          end
        end
      end
    end

    context 'when task returns redirect' do
      class RedirectPtrFlow < RWF::Flow
        task :first
        task :second
        task :third
        task :forth

        def first(*)
          RWF::PtrSuccess.new(:third)
        end

        def second(*)
          false
        end

        def third(*)
          RWF::EndSuccess.new
        end

        def forth(*)
          false
        end
      end

      let(:result) { RedirectPtrFlow.() }

      it { expect(result.success?).to be true }
    end
  end
end
