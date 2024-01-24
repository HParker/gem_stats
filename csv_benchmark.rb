require 'csv'
require 'benchmark'
require 'extralite'

input_queue = Queue.new
output_queue = Queue.new

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
      output_queue << path.reverse if path
    end
  }
end

csv = CSV.open("test.csv", "w")
reduce = Thread.new {
  until output_queue.closed? && output_queue.empty?
    csv << [output_queue.pop]
  end
  puts "done"
}

workers.each(&:join)
output_queue.close

reduce.join
feed.join

csv.close
