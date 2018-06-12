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
            false
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
  end
end
