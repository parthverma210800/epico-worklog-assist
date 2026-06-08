module Llm
  # Thin wrapper over the official Anthropic Ruby SDK. Centralizes the model id,
  # token ceiling, and how we read text out of the response, so callers
  # (Worklogs::AiComposer) just pass a system + user prompt and get a string back.
  #
  # The API key is read from ENV["ANTHROPIC_API_KEY"]; the underlying client is
  # built lazily so this loads (and can be injected in tests) without a key.
  #
  #   Llm::Client.new.complete(system: "...", user: "...")  # => "drafted text"
  class Client
    DEFAULT_MODEL = :"claude-opus-4-8"
    DEFAULT_MAX_TOKENS = 2_000

    # Raised when the LLM call fails (missing/invalid key, rate limit, outage),
    # so callers can return a clean error instead of a 500.
    class Error < StandardError; end

    def initialize(model: DEFAULT_MODEL, api_key: ENV["ANTHROPIC_API_KEY"])
      @model = model
      @api_key = api_key
    end

    def complete(system:, user:, max_tokens: DEFAULT_MAX_TOKENS)
      message = client.messages.create(
        model: @model,
        max_tokens: max_tokens,
        system_: [{ type: "text", text: system }],
        messages: [{ role: "user", content: user }]
      )

      message.content
             .select { |block| block.type == :text }
             .map(&:text)
             .join("\n")
             .strip
    rescue Anthropic::Errors::Error => e
      raise Error, "LLM request failed: #{e.message}"
    end

    private

    def client
      @client ||= @api_key ? Anthropic::Client.new(api_key: @api_key) : Anthropic::Client.new
    end
  end
end
