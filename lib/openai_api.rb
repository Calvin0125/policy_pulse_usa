# frozen_string_literal: true

class OpenaiApi
  def initialize
    @api_key = Rails.application.credentials.openai_api_key
    @model = 'gpt-3.5-turbo'
  end

  def get_text_response(prompt)
    response = HTTP.headers(
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    ).post('https://api.openai.com/v1/chat/completions', json: {
             model: 'gpt-3.5-turbo',
             messages: [{ role: 'user', content: prompt }],
             temperature: 0.7
           })

    JSON.parse(response.body)['choices'][0]['message']['content']
  end

  def legal_text_summary(text)
    part_summaries = []
    start_index = 0
    end_index = 47_999

    while start_index <= text.length
      text_part = text[start_index..end_index]
      part_summaries << legal_text_part_summary(text_part)
      start_index = end_index + 1
      end_index += 48_000
    end

    prompt = <<~TEXT
      You will be given multiple summaries of parts of the same legal text. Generate a 3
      paragraph summary of the summaries. The first paragraph should begin with the phrase 'This bill'
      and include the purpose of the bill, provisions, and rights and obligations conferred.
      The second paragraph should go more in depth than the first paragraph and include any
      relevant information the average American would want to know that was not included in the
      first paragraph. The third paragraph should include effective dates if known, repercussions
      for non-compliance, and any notable exceptions. Please do not include the phrase 'NEXT SUMMARY' in
      your final summary.
      Here are the summaries, joined by the phrase NEXT SUMMARY. #{part_summaries.join(' NEXT SUMMARY ')}
    TEXT

    get_text_response(prompt)
  end

  def legal_text_part_summary(text)
    # Model accepts 16k tokens as of 2024-07-02
    # Average of 4 chars per token, but punctuation can count as one token
    # 48000 is a safe estimate to make sure token limit is not exceeded
    raise StandardError, 'Text must be < 48,000 chars for part summary' if text.length > 48_000

    prompt = <<~TEXT
      Please summarize the following part of a legal text.#{' '}
      The summary should include the main purpose and objective of#{' '}
      this section, key provisions, and rights and obligations conferred or imposed.
      If this section includes effective dates, repercussions for non-compliance, and any
      notable exceptions, please state those. Use complete sentences and clear and concise language,
      avoiding legal jargon as much as possible. There is no need to mention the title as
      this will already be shown to the user. Here is the text: #{text}
    TEXT

    get_text_response(prompt)
  end
end
