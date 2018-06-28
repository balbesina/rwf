# RWF

Simple Ruby Workflow

## Installation

```sh
gem install rwf
```

## Direct Flow

### Direct flow diagram

![direct flow](img/diagram/direct_flow.png)

### Usage

```ruby
# TODO: rewrite to match diagram
# my_flow.rb
require 'rwf'

class NestedFlow < RWF::Flow
  task :fail_task

  def fail_task(*)
    puts 'am nested and i know it'
    false # return falsey - task result is failure
  end
end

class MyFlow < RWF::Flow
  task :task1
  task ->(*) { puts('lambda'); true }
  task NestedFlow
  error :error_task
  task :skipped_task
  cure :cure_task
  task :after_cure

  def task1(*)
    puts 'task1'
    true # return truthy - task result would be `success`
  end

  def error_task(params, *)
    puts 'error_task'
    params[:some_output] = 'hi from error_task'
  end

  def skipped_task(*)
    raise 'that task should not be called - flow state is now a `failure`'
  end

  # note that we can read some output of previous steps
  def cure_task(_params, some_output:, **)
    puts 'cure_task'
    puts "some output: '#{some_output}'"
    true # success of `cure` task restores the flow's state
  end

  # that task was called because the flow was cured
  def after_cure(*)
    puts 'after_cure'
    true
  end
end

MyFlow.()
```

The output would be:

```sh
task1
lambda
am nested and i know it
error_task
cure_task
some output: 'hi from error_task'
after_cure
```

## Flow GoTos

```ruby
# goto_flow.rb
class GotoFlow < RWF::Flow
  task :task1, on_success: :task3
  task :task2, on_error: :end
  task :some, ptr: :task3, on_success: :task2
  task :task4, on_success: :task5
  error :task5

  def task1(_params, result1: false, **)
    puts '-> task1'
    result1
  end

  def task2(_params, result2: nil, **)
    puts '-> task2'
    result2
  end

  def some(_params, result3: nil, **)
    puts '-> some'
    result3
  end

  def task4(_params, result4: nil, **)
    puts '-> task4'
    result4
  end

  def task5(*)
    puts '-> task5'
  end
end
```

```ruby
GotoFlow.()
```

```sh
-> task1
-> task5
```

```ruby
GotoFlow.(result1: true)
```

```sh
-> task1
-> some
-> task5
```

```ruby
GotoFlow.(result1: true, result3: true)
```

```sh
-> task1
-> some
-> task2
```

```ruby
GotoFlow.(result1: true, result3: true, result2: true)
```

```sh
-> task1
-> some
-> task2
-> some
-> task5
```
