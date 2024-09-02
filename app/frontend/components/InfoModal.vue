<template>
  <div>
    <v-dialog v-model="showModal">
      <v-card class="modal-background">
        <v-row>
          <v-col cols="auto">
            <v-icon @click="showModal = false" class="custom-color-icon mt-3 ml-3">mdi-close</v-icon>
          </v-col>
          <v-col>
            <v-card-title class="headline text-center">Frequently Asked Questions</v-card-title>
          </v-col>
          <v-col cols="auto"></v-col>
        </v-row>
        <v-card-text>
          <div v-for="(question, index) in questions"
            :key="index"
          >
            <p class="mb-1"><b>{{ question.title }}</b></p>
            <p class="mb-3" v-html="question.answer"></p>
          </div>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn @click="showModal = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
export default {
  name: "InfoModal",
  data() {
    return {
      showModal: true,
      questions: [
        {
          title: 'Where does your information come from?',
          answer: `The laws are retrieved from 
                  <a href="https://legiscan.com/legiscan" style="color: #e0e0e0;" 
                  target="_blank">LegiScan</a>. If the full text is
                  available it will be sent to ChatGPT to be summarized. LegiScan
                  and ChatGPT are fairly reliable but there is always a risk of
                  incorrect information from LegiScan or an inaccurate summary
                  from ChatGPT. If you are using this information to make legal
                  decisions, it’s best to read the full text directly and consult
                  with a lawyer.`
        },
        {
          title: 'How often is it updated?',
          answer: `LegiScan is queried daily to check for new laws and updates to 
                  the status or text of existing laws. If a new text is available, 
                  a new summary will be generated.`
        },
        {
          title: 'How do you make money?',
          answer: `I don’t. I am offering this as a free service because I believe 
                  that citizens should be able to inform themselves about laws that 
                  are being enacted. If it becomes popular I may put ads on the site 
                  to cover my costs and enable me to spend more time working on it, 
                  but I will never charge a fee or sell your data.`
        },
        {
          title: 'What prompt do you use for summarization?',
          answer: `Most laws exceed the context limit for ChatGPT, so I summarize 
                  them in parts. This is the prompt I use for summarizing the parts.
                  <br><br><blockquote class="ml-3">
                  Please summarize the following part of a legal text.
                  The summary should include the main purpose and objective of
                  this section, key provisions, and rights and obligations conferred or 
                  imposed. If this section includes effective dates, repercussions for 
                  non-compliance, and any notable exceptions, please state those. Use 
                  complete sentences and clear and concise language, avoiding legal jargon 
                  as much as possible. There is no need to mention the title as this will 
                  already be shown to the user. Here is the text: #{text}
                  </blockquote><br>
                  Then I send all of the part summaries again using this prompt.
                  <br><br><blockquote class="ml-3">
                  You will be given multiple summaries of parts of the same legal text. 
                  Generate a 3 paragraph summary of the summaries. The first paragraph should 
                  begin with the phrase 'This bill' and include the purpose of the bill, 
                  provisions, and rights and obligations conferred. The second paragraph 
                  should go more in depth than the first paragraph and include any relevant 
                  information the average American would want to know that was not included in 
                  the first paragraph. The third paragraph should include effective dates if known, 
                  repercussions for non-compliance, and any notable exceptions. Please do not include 
                  the phrase 'NEXT SUMMARY' in your final summary. Please make sure to separate each 
                  paragraph with two newline characters. Here are the summaries, joined by the phrase 
                  NEXT SUMMARY. #{part_summaries.join(' NEXT SUMMARY ')}
                  </blockquote>`
        },
        {
          title: 'What technologies power this application?',
          answer: `This is built on Ruby on Rails, Vite, Vue, Vuetify, the LegiScan API, and the 
                  OpenAI API. You can see the source code 
                  <a href="https://github.com/Calvin0125/policy_pulse_usa" style="color: #e0e0e0;"
                  target="_blank">here</a>.`
        }
      ]
    }
  }
}
</script>

<style scoped>
* {
  color: #e0e0e0;
}
a {
  color: #e0e0e0;
}
.modal-background {
  background-color: #505050;
}
.custom-color-icon {
  color: #e0e0e0;
}
</style>
