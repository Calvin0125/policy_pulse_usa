class OpenaiApi
  def initialize
    @api_key = Rails.application.credentials.openai_api_key
    @model = 'gpt-3.5-turbo'
  end

  def single_summary(text)
    # Model accepts 16k tokens as of 2024-07-02
    # Average of 4 chars per token, but punctuation can count as one token
    # 48000 is a safe estimate to make sure token limit is not exceeded
    if text.length > 48000
      raise StandardError, 'Text must be < 48,000 chars for single summary'
    end

    content = "Please give a 3 paragaph summary of the following legal text: #{text}"
    response = HTTP.headers(
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    ).post('https://api.openai.com/v1/chat/completions', json: {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: content }],
      temperature: 0.7
    })
    
    JSON.parse(response.body)['choices'][0]['message']['content']
  end
end