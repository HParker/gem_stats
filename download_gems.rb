require 'gems'
require 'json'
require 'rubygems'
require 'fileutils'
require 'rubygems/package'

unless File.exist?("all-gems.txt")
  puts "generating gem spec list"
  File.open("all-gems.txt", 'w') do |file|
    Gem::SpecFetcher.new.available_specs(:latest).first.each do |source, gems|
      gems.each do |tuple|
        gem_name = File.basename(tuple.spec_name, ".gemspec")
        gem_uri = source.uri.merge("/gems/#{gem_name}.gem")
        file.write(gem_uri.to_s + "\n")
      end
    end
  end
end

File.readlines("all-gems.txt").each do |gem_uri|
  gem_name = gem_uri.split("/").last.split(".").first
  gem_uri = gem_uri.strip.chomp
  gem_path = "vendor/zips/#{gem_name}.gem"
  unpacked_gem_path = "vendor/files/#{gem_name}"

  if File.exist?(gem_path)
  else
    sleep 0.1
    print gem_name
    print " "

    response = Net::HTTP.get_response(URI(gem_uri))
    next unless response.is_a?(Net::HTTPSuccess)
    File.write(gem_path, response.body)
    print "D"
  end

  if File.directory?(unpacked_gem_path)
  else
    Dir.mkdir(unpacked_gem_path)
    begin
      Gem::Package.new(gem_path).extract_files(unpacked_gem_path, "[!~]*")
    rescue => e
      # If the gem fails to extract, we'll just skip it
      puts e
      puts "UNPACK FAILED #{gem_name}"
      next
    end

    puts "U"
  end
end
