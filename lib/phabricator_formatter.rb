require 'json'

class PhabricatorTestResult
  attr_accessor :name
  attr_accessor :namespace
  attr_accessor :result
  attr_accessor :duration
  attr_accessor :details
  attr_accessor :path
  attr_accessor :coverage
  attr_accessor :engine

  def initialize(name, result)
    @name = name
    @result = result
  end

  def to_json(_generator)
    data = {
      name: @name,
      result: @result
    }

    # FIXME: use runtime access instead of manual labor?
    data[:namespace] = @namespace unless @namespace.nil?
    data[:duration] = @duration unless @duration.nil?
    data[:details] = @details unless @details.nil?
    data[:coverage] = @coverage unless @coverage.nil?
    data[:path] = @path unless @path.nil?
    data[:engine] = @engine unless @engine.nil?

    JSON.pretty_generate(data)
  end
end

class PhabricatorFormatter < XCPretty::Formatter
  EMPTY = ''.freeze

  def initialize(_use_unicode, _colorize)
    super(true, false)
    @results = []
    @cur_target = nil
    @cur_build_failures = []
    @build_start_time = nil
  end

  def push(result)
    @results.push(result)
  end

  def stop_build
    return if @cur_target.nil?

    no_errors = @cur_build_failures.count.zero?
    @cur_target.result = no_errors ? :pass : :broken
    @cur_target.details = @cur_build_failures.join("=======================\n") unless no_errors
    @cur_target.duration = Time.now.to_f - @build_start_time
    push(@cur_target)

    @cur_target = nil
  end

  def start_build(target, project, configuration)
    name = format('%s [%s]', target, configuration)
    return if !@cur_target.nil? && @cur_target.name == name

    stop_build

    @cur_target = PhabricatorTestResult.new(name, :broken)
    @cur_target.namespace = format('Build %s', project)
    @cur_build_failures = []
    @build_start_time = Time.now.to_f
  end

  def format_build_target(target, project, configuration)
    start_build(target, project, configuration)

    EMPTY
  end

  def format_test_suite_started(_name)
    stop_build
    EMPTY
  end

  def format_passing_test(suite, test, time)
    result = PhabricatorTestResult.new(test, :pass)
    result.duration = time.to_f
    result.namespace = scrub(suite)
    push(result)
    EMPTY
  end

  def format_failing_test(suite, test, reason, file_path)
    result = PhabricatorTestResult.new(test, :fail)
    result.namespace = scrub(suite)
    result.details = reason
    result.path = file_path
    push(result)
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
    parts = text.gsub(/\s/,'_').split('.')
    parts[1] || parts[0]
  end
end

PhabricatorFormatter
