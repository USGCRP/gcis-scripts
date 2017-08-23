#!/usr/bin/env ruby

# Helper script that takes any GCIS resource list json and converts it to a
# ElasticSearch Bulk API friendly format.
#
# Example:
#   curl https://data.globalchange.gov/references.json?all=1 >gcis_references.json
#   ./gcis_resources_to_elasticsearch_bulk.rb -i identifier -g gcis_references.json -e references_es_bulk.json
#   curl -H 'Content-Type: application/x-ndjson' -XPOST "http://[YOUR_ES]:9200/gcis/reference/_bulk" --data-binary @references_es_bulk.json
#
#   Known Issues: GCIS sometimes preceeds a key with ".". This causes ES to throw up. A quick find-and-replace in vim has served me well.

require 'optparse'
require "json"

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: optparse1.rb [options]"

  options[:id_field] = "identifier"
  opts.on( '-i', '--id_field STRING', 'Which field on the resource should serve as the ElasticSearch _id field' ) do |id|
    options[:id_field] = id
  end

  options[:gcis_file] = nil
  opts.on( '-g', '--gcis_file FILE', 'The file containing the GCIS resource list, as JSON' ) do |file|
    options[:gcis_file] = file
  end

  options[:es_file] = nil
  opts.on( '-e', '--es_file FILE', 'The file to write the ES bulk API data to' ) do |file|
    options[:es_file] = file
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

puts "Got arguments ID: #{options[:id_field]} - GCIS File: #{options[:gcis_file]} - ES File: #{options[:es_file]}"

identifier_name = options[:id_field]
input = File.read(options[:gcis_file])
parsed = JSON.parse(input)

parsed.each do |resource|
  #puts resource.to_s
  File.open(options[:es_file], mode="a+") do |file|
    file.write(JSON.generate( { :index => { :_id => resource[identifier_name] } } ))
    file.write("\n")
    file.write(JSON.generate(resource))
    file.write("\n")
  end
end

