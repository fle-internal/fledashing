#!/usr/bin/env ruby
require 'rest-client'
require 'json'
require 'date'
require 'yaml'

CONFIG_FILE = YAML.load_file('config.yml')
SECRETS_FILE = YAML.load_file('secrets.yml')
git_token = SECRETS_FILE["github_all_access_key"]
git_owner = CONFIG_FILE["git_owner"]
git_project = CONFIG_FILE["git_project"]

SCHEDULER.every '20m', :first_in => 0 do |job|
    uri = "https://api.github.com/repos/#{git_owner}/#{git_project}/milestones?access_token=#{git_token}"
    puts "Getting milestone data from GitHub"
    response = RestClient.get uri
    milestones = JSON.parse(response.body, symbolize_names: true)

    # Remove all the milestones with no due date, or where all the issues are closed.
    milestones.select! { |milestone| !milestone[:due_on].nil? and (milestone[:open_issues] > 0) }

    if milestones.length > 0
        milestones.sort! { |a,b| a[:due_on] <=> b[:due_on] }

        next_milestone = milestones.first
        days_left = (Date.parse(next_milestone[:due_on]) - Date.today).to_i
        if days_left > 0
            due = "Due in #{days_left} days"
        elsif days_left == 0
            due = "Due today"
        else
            due = "Overdue by #{days_left.abs} days"
        end

        send_event('git_next_milesone', {
            text: "#{next_milestone[:title] or 'Unnamed Milestone'}, #{due}",
            moreinfo: "#{next_milestone[:open_issues]}/#{next_milestone[:open_issues] + next_milestone[:closed_issues]} issues remain"
        })

    else
        # There are no milestones left with open issues.
        send_event('git_next_milesone', {
            text: "None",
            moreinfo: ""
        })

    end
end # SCHEDULER