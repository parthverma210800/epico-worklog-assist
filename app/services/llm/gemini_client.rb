require "net/http"
require "json"
require "uri"

module Llm
  # Free-tier alternative to Llm::Client, used only for local prototype testing
  # (Google AI Studio gives a free API key, no card). Same interface as
  # Llm::Client#complete so it drops into AiComposer unchanged.
  #
  # NOTE: production Epico uses Claude (Llm::Client). This is a test-only backend,
  # selected via Llm.default when GEMINI_API_KEY is set.
  #
  #   Llm::GeminiClient.new.complete(system: "...", user: "...")
  class GeminiClient
    BASE = "https://generativelanguage.googleapis.com/v1beta".freeze
    DEFAULT_MODEL = ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash")

    class AuthError < StandardError; end
    class RequestError < StandardError; end

    def initialize(model: DEFAULT_MODEL, api_key: ENV["GEMINI_API_KEY"])
      @model = model
      @api_key = api_key
    end

    def complete(system:, user:, max_tokens: 2_000)
      uri = URI("#{BASE}/models/#{@model}:generateContent")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-goog-api-key"] = @api_key
      request.body = JSON.generate(
        system_instruction: { parts: [{ text: system }] },
        contents: [{ role: "user", parts: [{ text: user }] }],
        generationConfig: { maxOutputTokens: max_tokens }
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

      case response.code.to_i
      when 200
        data = JSON.parse(response.body)
        data.dig("candidates", 0, "content", "parts").to_a.map { |part| part["text"] }.join.strip
      when 401, 403 then raise AuthError, "Gemini auth failed (#{response.code})"
      else raise RequestError, "Gemini request failed (#{response.code})"
      end
    end
  end
end
