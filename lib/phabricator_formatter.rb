require 'json'

class PhabricatorTestResult
  attr_accessor :name
  attr_accessor :namespace
  attr_accessor :link
  attr_accessor :result
  attr_accessor :duration
  attr_accessor :extra
  attr_accessor :userData

  def to_json(_generator)
    JSON.pretty_generate(
      name: @name,
      namespace: @namespace,
      link: @link,
      result: @result,
      duration: @duration,
      extra: @extra,
      userData: @userData
    )
  end
end

class PhabricatorFormatter < XCPretty::Formatter
  EMPTY = ''.freeze

  def initialize(_use_unicode, _colorize)
    super(true, false)
    @results = []
    @cur_target = nil
    @cur_build_failures = []
  end

  def stop_build
    return if @cur_target.nil?

    result = PhabricatorTestResult.new
    result.name = @cur_target
    result.result = @cur_build_failures.count.zero? ? 'pass' : 'broken'
    result.userData = @cur_build_failures.join("=================================\n")

    @results.push(result)
  end

  def start_build(target, project, configuration)
    stop_build
    @cur_target = format('%s[%s] (%s)', target, configuration, project)
    @cur_build_failures = []
  end

  def format_build_target(target, project, configuration)
    start_build(target, project, configuration)

    EMPTY
  end

  def format_test_suite_started(_name)
    stop_build
    EMPTY
  end

  def push_result(name, result)
    item = PhabricatorTestResult.new
    item.name = name
    item.result = result
    @results.push(item)
  end

  def format_passing_test(suite, test, _time)
    push_result(format('%s: %s', suite, test), 'pass')
    EMPTY
  end

  def format_failing_test(suite, test, reason, file_path)
    name = format('%s: %s - %s (%s)', suite, test, reason, file_path)
    push_result(name, 'fail')

    EMPTY
  end

  def push_failure_message(message)
    @cur_build_failures.push(message)
  end

  def format_compile_error(_file, file_path, reason, line, cursor)
    message = format('%s:%s:%s error: %s', file_path, line.to_s, cursor.to_s, reason)
    push_failure_message(message)

    EMPTY
  end

  def format_error(message)
    push_failure_message(message)
    EMPTY
  end

  def format_undefined_symbols(message, symbol, reference)
    msg = format('undefined symbol %s: %s (%s)', symbol, message, reference)
    push_failure_message(msg)
    EMPTY
  end

  def format_duplicate_symbols(message, file_paths)
    msg = format('duplicate symbol %s in %s', message, file_paths.join(', '))
    push_failure_message(msg)
    EMPTY
  end

  def format_warning(_message)
    EMPTY
  end

  def format_ld_warning(_reason)
    EMPTY
  end

  def format_test_summary(_executed_message, _failures_per_suite)
    stop_build
    JSON.pretty_generate(@results)
  end

  def scrub(text)
    text.gsub(/\s/,'_').split('.').first
  end
end

PhabricatorFormatter
