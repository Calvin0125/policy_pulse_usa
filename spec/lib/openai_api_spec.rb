# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenaiApi, type: :model do
  let(:openai_api) { OpenaiApi.new }

  describe '#get_text_response', :vcr do
    it 'returns a response from the OpenAI API' do
      prompt = 'What is the capital of France?'
      response = openai_api.get_text_response(prompt)

      expect(response).to be_a(String)
      expect(response).to include('Paris')
    end
  end

  describe '#legal_text_part_summary' do
    it 'returns a summary for a given text part' do
      text = 'This is a test legal text that needs to be summarized.'

      allow(openai_api).to receive(:get_text_response).and_return('This is a summary of the legal text.')

      summary = openai_api.legal_text_part_summary(text)

      expect(summary).to eq('This is a summary of the legal text.')
      expect(openai_api).to have_received(:get_text_response).with(
        a_string_including('Please summarize the following part of a legal text')
      )
    end

    it 'raises an error if the text is too long' do
      long_text = 'a' * 48_001

      expect do
        openai_api.legal_text_part_summary(long_text)
      end.to raise_error(StandardError,
                         'Text must be < 48,000 chars for part summary')
    end
  end

  describe '#legal_text_summary' do
    it 'returns a combined summary for a given legal text' do
      text = 'This is a long legal text that needs to be summarized in parts.' * 1000

      allow(openai_api).to receive(:legal_text_part_summary).and_return('This is a part summary.')

      combined_summary_prompt = <<~TEXT
        You will be given multiple summaries of parts of the same legal text. Generate a 3
        paragraph summary of the summaries. The first paragraph should begin with the phrase 'This bill'
        and include the purpose of the bill, provisions, and rights and obligations conferred.
        The second paragraph should go more in depth than the first paragraph and include any
        relevant information the average American would want to know that was not included in the
        first paragraph. The third paragraph should include effective dates if known, repercussions
        for non-compliance, and any notable exceptions. Please do not include the phrase 'NEXT SUMMARY' in
        your final summary. Please make sure to separate each paragraph with two newline characters.
        Here are the summaries, joined by the phrase NEXT SUMMARY. This is a part summary. NEXT SUMMARY This is a part summary.
      TEXT

      allow(openai_api).to receive(:get_text_response).and_return('This is the combined summary of the legal text.')

      summary = openai_api.legal_text_summary(text)

      expect(summary).to eq('This is the combined summary of the legal text.')
      expect(openai_api).to have_received(:get_text_response).with(combined_summary_prompt)
    end
  end
end
