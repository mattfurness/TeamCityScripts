require 'net/http'
require 'json'
require 'FileUtils'

lamp_path = ENV['lamp_path']
branch = ENV['branch']
build_type = ENV['build_type']
output_dir = ENV['output_dir']

teamcity_server = ENV['teamcity_server']
teamcity_username = ENV['teamcity_username']
teamcity_password = ENV['teamcity_password']

tfs_server = ENV['tfs_server']
tfs_username = ENV['tfs_username']
tfs_pwd = ENV['tfs_pwd']

output_filename = ENV['output_filename'] || 'workitems.html'

def make_request(changeset_url, user, pwd)
  uri = URI(changeset_url)
  req = Net::HTTP::Get.new(changeset_url)
  req.basic_auth user, pwd
  req['accept'] = 'application/json'

  Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
end

build_types_url = "#{teamcity_server}/httpAuth/app/rest/buildTypes/id:#{build_type}/builds"
res = make_request(build_types_url, teamcity_username, teamcity_password)
builds = JSON.parse(res.body)['build']

if builds.to_a.empty?
  return
end

build_id = builds.first['id']

changeset_url = "#{teamcity_server}/httpAuth/app/rest/changes?build=id:#{build_id}"

res = make_request(changeset_url, teamcity_username, teamcity_password)
changes = JSON.parse(res.body)['change']

if changes.to_a.empty?
  return
end

min_max_changes = changes.
    minmax { |a,b| a['version'] <=> b['version'] }.
    collect { |c| c['version'] }

puts "from change set #{min_max_changes[0]} to #{min_max_changes[1]}"

exec(lamp_path, '-m', "ChangesetRange", '-s', tfs_server,
     '-u', tfs_username, '-p', tfs_pwd,
     '-b', branch, '-fc', min_max_changes[0],
     '-tc', min_max_changes[1], '-o', "#{output_dir}\\#{output_filename}")