<template>
  <div id="background">
    <info-modal ref="infoModal"></info-modal>
    <v-container class="d-flex flex-column align-center justify-center">
      <h1 class="page-title mb-3">Policy Pulse USA</h1>
      <img width="20%" src="../assets/images/usa_flag.svg" alt="American Flag" class="mb-3"/>
      <div class="pagination-controls">
        <v-btn @click="goToPreviousPage" :disabled="currentPage === 1">
          Previous
        </v-btn>
        <span class="page-indicator">Page {{ currentPage }}</span>
        <v-btn @click="goToNextPage">
          Next
        </v-btn>
      </div>
      <v-row class="mt-3">
        <v-col cols="auto">
          <v-icon @click="openInfoModal" class="clickable mb-0">mdi-information</v-icon>
        </v-col>
        <v-col>
          <h2>Federal Bills Ordered by Most Recently Created or Updated</h2>
        </v-col>
        <v-col cols="auto"></v-col>
      </v-row>
      <v-row class="mt-2" align="center" justify="center">
        <v-switch v-model="onlyWithSummary" inset>
          <template #label>
            <span class="text-h6 font-weight-bold">
              Only Show Bills With Summaries
            </span>
          </template>
        </v-switch>
      </v-row>
    </v-container>
    <v-container>
      <v-row>
        <v-col
          v-for="(bill, index) in bills"
          :key="index"
          cols="12"
        >
          <v-card class="mx-auto bill-card">
            <v-card-title class="bill-title">{{ bill.title }}</v-card-title>
            <v-card-subtitle class="bill-attribute">Status: {{ capitalize(bill.status) }}</v-card-subtitle>
            <v-card-subtitle class="bill-attribute">Status Date: {{ bill.status_last_updated }}</v-card-subtitle>
            <v-card-text v-if="bill.summary" class="bill-attribute">
              <div v-for="(billSummaryPart, index) in bill.summary.split(`\n\n`)">
                <p>{{ billSummaryPart }}</p>
                <br>
              </div>
            </v-card-text>
            <v-card-text v-else class="bill-attribute">Text not available yet.</v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
import axios from 'axios';
import InfoModal from './InfoModal.vue'

export default {
  components: {
    InfoModal,
  },
  data() {
    return {
      currentPage: 1,
      bills: [],
      onlyWithSummary: false
    };
  },
  beforeMount() {
    this.fetchBills();
  },
  methods: {
    async fetchBills() {
      const response = await axios.get('/bills', { headers: { 'Accept': 'application/json' }, params: { page: this.currentPage, onlyWithSummary: this.onlyWithSummary} });
      this.bills = response.data.bills;
    },
    openInfoModal() {
      this.$refs.infoModal.showModal = true;
    },
    capitalize(string) {
      return string.charAt(0).toUpperCase() + string.slice(1).toLowerCase();
    },
    goToNextPage() {
      this.currentPage += 1;
      this.fetchBills();
    },
    goToPreviousPage() {
      this.currentPage -= 1;
      this.fetchBills();
    }
  },
  watch: {
    onlyWithSummary(newVal, oldVal) {
      this.currentPage = 1
      this.fetchBills()
    }
  }
}
</script>

<style scoped>
* {
  color: #e0e0e0;
}

#background {
  background-color: #2c2c2c;
  margin: 0;
  padding: 0;
}

.page-title {
  font-size: 2.5rem;
}

.bill-title {
  font-size: 1.5rem;
  font-weight: bold;
  white-space: normal;
  overflow: visible;
}

.bill-attribute {
  font-size: 1rem;
  opacity: 1;
}

.bill-card {
  background-color: #3a3a3a;
}

.pagination-controls {
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 20px 0;
}

.page-indicator {
  margin: 0 15px;
  font-size: 1.2rem;
}

:deep(.v-switch .v-label) {
  opacity: 1 !important;
  color: #e0e0e0 !important;
}
</style>