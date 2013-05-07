require 'net/http'
require 'uri'
require 'net/https'
require 'openssl'
require 'rubygems'
require 'json'
require 'MyConfig'


# Function getissues, takes the offset
def getissues(offset)
	contentURI = URI(MyConfig::Tracker + "&offset=#{offset}&limit=100&nometa=1")
	# puts offset
	req = Net::HTTP::Get.new(contentURI.path + '?' + contentURI.query)
	req.add_field 'X-Redmine-API-Key', MyConfig::Apikey
	https = Net::HTTP.new(contentURI.host, contentURI.port)
	https.use_ssl = true

	resp = https.start { |cx| cx.request(req) }
	systems = JSON.parse(resp.body)
end

# Loop through the offset by 100 and add the issues subject to the systems_total
systems_total = Array.new
(0..300).step(100) do |n|
	getissues(n)["issues"].each { |issue| 
		systems_total << issue["subject"]
		# puts systems_total.count.to_s + issue["subject"]
	}
end

# Open the file of hostnames reported from mcollective, just the hostnames nothing more
lines = File.readlines(ARGV[0])

issues_to_create = Array.new

match_count = 0

puts systems_total.count
systems_total.each { |systems| 
	# puts systems
}

# Go through each line of the file and check it against each maintenance issue from redmine
# I think there's a better way to do this.
lines.each { |line|
	match = 0
	systems_total.each { |issue|
		# p "issue " + issue["subject"]
		# p "line " + line
		# p "does: #{issue} match: #{line.strip} ? #{issue.include? line.strip}"
		if issue.include? line.strip 
			# puts "Match!"
			# p "Match: " + "issue " + issue["subject"] + "line " + line
			match =  1
			match_count = match_count + 1
		else
			# puts "No Match"
		end
	}
	if match == 0
		issues_to_create << line.strip
	end
}


def postissues(issues)
	# Post the issues to create
	postURI = URI('MyConfig::Post')
	# build this then make one big post instead of a bunch of small ones.
	issues_to_create.each { |line| 
	# try to see what environment to put this in
	if line.match("prod")
		env = "Prod"
	elsif line.match("stage")
		env = "Stage"
	elsif line.match("test")
		env = "Test"
	elsif line.match("dev")
		env = "Dev"
	elsif line.match("pilot")
		env = "Pilot"
	else
		env = ""
	end

# This is a template to use to create each maintenance issue
create_issue = <<END_MY_STRING_PLEASE 
{
  "issue": {
    "project_id": #{MyConfig::ProjectId},
    "tracker_id": #{MyConfig::TrackerId},
    "subject": "#{line}",
    "priority_id": 4,
    "custom_fields":
    	[
    		{"name":"Environment","id":2,"value":"#{env}"}
    	]
  }
}
END_MY_STRING_PLEASE

	post = Net::HTTP::Post.new(postURI.path, initheader = {'Content-Type' =>'application/json'})
	https_post = Net::HTTP.new(postURI.host, PostURI.port)
	https_post.use_ssl = true

	post.add_field 'X-Redmine-API-Key', MyConfig::Apikey
	post.body = create_issue

	resp = https_post.start { |cx| cx.request(post) }
	puts resp.code
	puts resp.message

	puts "match_count #{match_count}"
	puts "issues to create: #{issues_to_create.count}"
	break
}
end


if issues_to_create.count > 0
	postissues(issues_to_create)
else
	puts "No issues to create"
end



