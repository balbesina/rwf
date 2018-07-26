# frozen_string_literal: true

require_relative '../../lib/rwf'

# direct flow sample. shows basic usage of tasks, errors, and cures
class DirectFlow < RWF::Flow
  TESTED_VERSION = '0.0.4'
  WARN_VERSION_DIFF = "Tested in version #{TESTED_VERSION}, your version is #{RWF::Version.version}"

  def initialize
    super
    puts WARN_VERSION_DIFF unless RWF::Version.version == TESTED_VERSION
  end

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
