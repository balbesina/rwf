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
# docs/diagram/direct_flow.rb
class DirectFlow < RWF::Flow
  task :task1
  task :task2
  error :error3
  task :task4
  error :error5
  task :task6
  cure :cure7
  task :task8

  def task1(_params, title:, task_result1: true, **)
    puts "\n-> #{title}"
    puts 'task1'
    task_result1
  end

  def task2(_params, task_result2: true, **)
    puts 'task2'
    task_result2
  end

  def error3(_params, task_result3: true, **)
    puts 'error3'
    task_result3
  end

  def task4(_params, task_result4: true, **)
    puts 'task4'
    task_result4
  end

  def error5(_params, task_result5: true, **)
    puts 'error5'
    task_result5
  end

  def task6(_params, task_result6: true, **)
    puts 'task6'
    task_result6
  end

  def cure7(_params, task_result7: false, **)
    puts 'cure7'
    task_result7
  end

  def task8(_params, task_result8: true, **)
    puts 'task8'
    task_result8
  end
end

DirectFlow.(title: 'Success Flow')
DirectFlow.(title: 'Failure Flow', task_result4: false)
DirectFlow.(title: 'Cure Flow', task_result4: false, task_result7: true)
```

The output would be:

```sh
-> Success Flow
task1
task2
task4
task6
task8

-> Failure Flow
task1
task2
task4
error5
cure7

-> Cure Flow
task1
task2
task4
error5
cure7
task8
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
