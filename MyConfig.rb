module MyConfig
  Apikey = ''
  Host = ''
  ProjectId = ''
  TrackerId = ''
  Tracker = "https://#{Host}/issues.json?project_id=#{ProjectId}&tracker_id=#{TrackerId}&nometa=1"
  Post = "https://#{Host}/issues.json"
 end