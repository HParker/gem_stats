require 'ripper'

File.open("err_out_files.txt", 'w') do |err_out|
  File.open("valid_plus_c_files.txt", 'w') do |output|
    Dir.glob("vendor/files/**/*").each do |filepath|
      if File.directory?(filepath)
        print "d"
        next
      end
      begin
        source = File.read(filepath)
      rescue
        print 'err'
        next
      end
      r = Ripper.new(source, filepath)
      if r.error? || !system("ruby -c #{filepath}")
        print 'x'
        err_out.write("#{filepath}\n")
      else
        print '.'
        output.write("#{filepath}\n")
      end
    end
    puts ""
  end
end
