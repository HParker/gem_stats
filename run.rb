# frozen_string_literal: true
require 'benchmark'
require_relative 'storage'
require_relative 'node_visitor'
require_relative 'stats_visitor'

# storage = NullStorage.new
storage = Storage.new
storage.setup

File.readlines("../all-gems/valid_and_c_files.txt").each do |filepath|
  next if storage.db.query_single_value("SELECT filepath FROM parse_times WHERE filepath = ? LIMIT 1", filepath.chomp)

  stats_visitor = StatsVisitor.new(storage, filepath.chomp)
  # node_visitor = NodeTypeVisitor.new(storage, filepath.chomp)

  begin
    filepath = filepath.chomp
    file_content = File.read("../all-gems/" + filepath)
    file_bytes = file_content.bytesize

    puts "#{filepath.chomp}: #{file_bytes}"

    result = nil
    time = Benchmark.realtime { result = Prism.parse(file_content) }

    result.value.accept(stats_visitor)
    # result.value.accept(node_visitor)

    storage.db.execute "INSERT INTO parse_times (filepath, bytes, time) VALUES (?, ?, ?)", filepath, file_bytes, time
  rescue SystemStackError => e
    puts "SystemStackError"
    puts filepath
    puts e
    next
  end
end
