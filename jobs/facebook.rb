#!/usr/bin/env ruby
require 'net/http'
require 'json'

facebook_graph_username = 'learningequality'

SCHEDULER.every '30m', :first_in => 0 do |job|
  http = Net::HTTP.new("graph.facebook.com")
  response = http.request(Net::HTTP::Get.new("/#{facebook_graph_username}"))
  if response.code != "200"
    puts "facebook graph api error (status-code: #{response.code})\n#{response.body}"
  else 
    data = JSON.parse(response.body)
    if data['likes']
      if defined?(send_event) 
        send_event('facebook_likes', current: data['likes'])
        send_event('facebook_checkins', current: data['checkins'])
        send_event('facebook_were_here_count', current: data['were_here_count'])
        send_event('facebook_talking_about_count', current: data['talking_about_count'])
      else
        printf "Facebook likes: %d, checkins: %d, were_here_count: %d, talking_about_count: %d\n",
          data['likes'],
          data['checkins'],
          data['were_here_count'],
          data['talking_about_count']
      end
    end
  end
end
