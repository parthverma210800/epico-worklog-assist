require "net/http"
require "json"
require "uri"

module Integrations
  module Github
    # Live GitHub client. Uses a connected user's OAuth/PAT token to read only what
    # that user can already see (per-user delegated access — no org grant needed).
    # Fetches the user's authored pull requests and commits in a date range and
    # normalizes them to Activity objects.
    #
    #   Integrations::Github::Client.new(token: tok).activities(from:, to:)
    class Client
      BASE = "https://api.github.com".freeze
      API_VERSION = "2022-11-28".freeze

      class AuthError < StandardError; end
      class RequestError < StandardError; end

      def initialize(token:, login: nil)
        @token = token
        @login = login
      end

      # Activities authored by the user between two dates (inclusive).
      def activities(from:, to:)
        author = login
        search_pull_requests(author, from, to) + search_commits(author, from, to)
      end

      # The authenticated user's GitHub login (cached).
      def login
        @login ||= get_json("/user").fetch("login")
      end

      # Branch names in a repo (newest API page; up to 100).
      #   branches("org/epp") => [{name:, sha:}, ...]
      def branches(repo)
        get_json("/repos/#{repo}/branches", per_page: 100).map do |b|
          { name: b["name"], sha: b.dig("commit", "sha") }
        end
      end

      # Commits authored by `author` on `branch` of `repo` during a single day,
      # tagged with the branch so the story can be derived from the branch name.
      def commits_on(repo:, branch:, author:, date:)
        get_json(
          "/repos/#{repo}/commits",
          sha: branch, author: author,
          since: "#{date.iso8601}T00:00:00Z", until: "#{date.iso8601}T23:59:59Z",
          per_page: 100
        ).map do |item|
          Activity.new(
            kind: :commit,
            repo: repo,
            ref: "commit:#{item['sha'].to_s[0, 7]}",
            title: item.dig("commit", "message").to_s.lines.first&.strip,
            occurred_on: date,
            url: item["html_url"],
            branch: branch
          )
        end
      end

      private

      def search_pull_requests(author, from, to)
        query = "author:#{author} type:pr created:#{from.iso8601}..#{to.iso8601}"
        get_json("/search/issues", q: query, per_page: 100).fetch("items", []).map do |item|
          Activity.new(
            kind: :pull_request,
            repo: repo_from_html_url(item["html_url"]),
            ref: "PR##{item['number']}",
            title: item["title"],
            occurred_on: Date.parse(item["created_at"]),
            url: item["html_url"]
          )
        end
      end

      def search_commits(author, from, to)
        query = "author:#{author} committer-date:#{from.iso8601}..#{to.iso8601}"
        get_json("/search/commits", q: query, per_page: 100).fetch("items", []).map do |item|
          Activity.new(
            kind: :commit,
            repo: item.dig("repository", "full_name"),
            ref: "commit:#{item['sha'].to_s[0, 7]}",
            title: item.dig("commit", "message").to_s.lines.first&.strip,
            occurred_on: Date.parse(item.dig("commit", "author", "date")),
            url: item["html_url"]
          )
        end
      end

      # "https://github.com/org/epp/pull/123" -> "org/epp"
      def repo_from_html_url(html_url)
        URI(html_url).path.split("/")[1, 2].join("/")
      end

      def get_json(path, **params)
        uri = URI("#{BASE}#{path}")
        uri.query = URI.encode_www_form(params) unless params.empty?

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{@token}"
        request["Accept"] = "application/vnd.github+json"
        request["X-GitHub-Api-Version"] = API_VERSION
        request["User-Agent"] = "epico-worklog-assist"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response.code.to_i
        when 200 then JSON.parse(response.body)
        when 401, 403 then raise AuthError, "GitHub auth failed (#{response.code})"
        else raise RequestError, "GitHub request failed (#{response.code})"
        end
      end
    end
  end
end
