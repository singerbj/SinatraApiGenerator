#!/usr/bin/env ruby

require 'json'
require 'active_support/inflector'

entities = []
if ARGV[0]
	# read in json
	json = File.open(ARGV[0], 'rb') { |f| f.read }
	#json = '[{"title": "user","attributes": {"name": "string","phone": "integer"}},{"title": "product","attributes": {"name": "string","price": "integer"}}]'
	entities = JSON.parse(json)
end

File.delete('./NEW_server.rb') if File.exist?('./NEW_server.rb')
File.delete('./NEW_Gemfile') if File.exist?('./NEW_Gemfile')

def writeToServer(string)
	File.open('./NEW_server.rb', 'a') { |f| f.write("#{string}\n") }
end

def writeToGemfile(string)
	File.open('./NEW_Gemfile', 'a') { |f| f.write("#{string}\n") }
end

# write to gemfile
[	
	"source \'https://rubygems.org\'",
	"",
	"gem \'sinatra\'",
	"gem \'activerecord\'",
	"gem \'sqlite3\'",
	""
].each do |s|
	writeToGemfile(s);
end

# write to server
[
	"require \'sinatra\'",
	"require \'json\'",
	"require \'active_record\'",
	"require \'sqlite3\'",
	"",
	"ActiveRecord::Base.establish_connection(adapter: \'sqlite3\', database: \'dbfile.sqlite3\')",
	""
].each do |s|
	writeToServer(s);
end

entities.each do |entity|
	writeToServer("class #{entity["title"].downcase.capitalize!} < ActiveRecord::Base\nend")	
end

entities.each do |entity|
	writeToServer("if !ActiveRecord::Base.connection.table_exists? \'#{entity["title"].downcase.pluralize}\'")
	writeToServer("    ActiveRecord::Migration.class_eval do")
	writeToServer("        create_table :#{entity["title"].downcase.pluralize} do |t|")
	entity["attributes"].each do |key, value|			
		writeToServer("        t.#{value.downcase} :#{key.downcase}")
	end
	writeToServer("        end")
	writeToServer("    end")
	writeToServer("end")
end  

[
	"configure do",
	"  set :bind, \'0.0.0.0\'",
	"  set :public_folder, \'.\'",
	"end",
	"",
	"after { ActiveRecord::Base.connection.close }",
	"",
	"get \"/\" do",
	"	\"Hello World!\"",
	"end",
	""
].each do |s|
	writeToServer(s);
end

entities.each do |entity|
	endpointName = entity["title"].downcase.pluralize
	entityCapitalized = entity["title"].downcase.capitalize
	[
		"get \'/#{endpointName}/?\' do",
		"	#{entityCapitalized}.all.to_json",
		"end",
		"",
		"get \'/#{endpointName}/:id/?\' do |id|",
		" 	if id",
		" 	 	#{entityCapitalized}.find(id).to_json",
		" 	else",
		" 	    \"Error: ID not specified.\"",
		" 	end",
		"end",
		"",
		"post \'/#{endpointName}/?\' do",
		"	request.body.rewind",
		"	j = JSON.parse(request.body.read)",
		"	o = #{entityCapitalized}.find(id)",
		"	j.each do |key, value|",
		"		o[key] = value",
		"	end",
		"	o.save!",
		"	o.to_json",
		"end",
		"",
		"put \'/#{endpointName}/:id/?\' do |id|",
		"   if id",
		"		request.body.rewind",
		"		j = JSON.parse(request.body.read)",
		"		o = #{entityCapitalized}.find(id)",
		"		j.each do |key, value|",
		"			o[key] = value",
		"		end",
		"		o.save!",
		"		o.to_json",
		" 	else",
		" 	    \"Error: ID not specified.\"",
		" 	end",
		"end",
		"",
		"delete \'/#{endpointName}/:id/?\' do |id|",
		"   if id",
		"      o = #{entityCapitalized}.find(id)",
		"      o.destroy!",
		"      id",
		" 	else",
		" 	    \"Error: ID not specified.\"",
		" 	end",
		"end",
		""
	].each do |s|
		writeToServer(s);
	end
end


