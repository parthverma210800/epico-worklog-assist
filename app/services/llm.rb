module Llm
  # Picks the LLM backend. Production default is Claude (Llm::Client). For free
  # local testing, set GEMINI_API_KEY (or LLM_PROVIDER=gemini) to use Gemini.
  def self.default
    if ENV["LLM_PROVIDER"] == "gemini" || ENV["GEMINI_API_KEY"].present?
      GeminiClient.new
    else
      Client.new
    end
  end
end
