require 'csv'
require 'benchmark'
require 'extralite'
require 'prism'
require_relative 'stats_visitor'

input_queue = Queue.new
output_queue = Queue.new


db = Extralite::Database.new("bench_test.db")
db.execute "PRAGMA journal_mode = OFF"
db.execute "PRAGMA sychronous = 0"
db.execute "PRAGMA cache_size = 1000000"
db.execute "PRAGMA locking_mode = EXCLUSIVE"
db.execute "PRAGMA temp_store = MEMORY"
db.execute "CREATE TABLE IF NOT EXISTS lines(content TEXT UNIQUE ON CONFLICT IGNORE)"

feed = Thread.new {
  File.open("v_small_sample.txt").each_line do |filepath|
    filepath.chomp!
    puts filepath.inspect
    input_queue << filepath if filepath
  end
  puts "ALL QUEUED #{input_queue.size}"
  input_queue.close
}

workers = []
6.times do |i|
  workers << Thread.new {
    until input_queue.closed? && input_queue.empty?
      path = input_queue.pop
      if path
        res = Prism.parse("../all_gems/" + path)
        res.value.accept(StatsVisitor.new(db, path))
      end

      # db.execute("INSERT INTO lines (content) VALUES (?)", path.reverse) if path
      # output_queue << path.reverse if path
    end
  }
end

reduce = Thread.new {
  until output_queue.closed? && output_queue.empty?
    path = output_queue.pop
    # db.execute("INSERT INTO lines (content) VALUES (?)", path) if path
  end
  puts "done"
}

workers.each(&:join)
output_queue.close

reduce.join
feed.join

db.close
