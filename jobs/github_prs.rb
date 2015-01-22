require 'octokit'

SCHEDULER.every '1m', :first_in => 0 do |job|
  client = Octokit::Client.new(:access_token => "2c1f154914e0bd73e1c3c738c1a90d64647359a8")
  my_organization = "learningequality"
  repos = client.organization_repositories(my_organization).map { |repo| repo.name }
 
  open_pull_requests = repos.inject([]) { |pulls, repo|
    client.pull_requests("#{my_organization}/#{repo}", :state => 'open').each do |pull|
      pulls.push({
        title: pull.title,
        repo: repo,
        updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
        creator: "@" + pull.user.login,
      })
    end
    pulls
  }

  send_event('pull_requests', { header: "Open Pull Requests", pulls: open_pull_requests })
end
