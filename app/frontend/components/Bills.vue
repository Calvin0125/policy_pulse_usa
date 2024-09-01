<template>
  <div id="background">
    <v-container class="d-flex flex-column align-center justify-center">
      <h1 class="page-title mb-3">Policy Pulse USA</h1>
      <img width="20%" src="../assets/images/usa_flag.svg" alt="American Flag" />
      <h3 class="mt-4">Federal Bills Ordered by Most Recently Created or Updated</h3>
    </v-container>
    <v-container>
      <v-row>
        <v-col
          v-for="(bill, index) in bills"
          :key="index"
          cols="12"
        >
          <v-card class="mx-auto bill-card" max-width="800">
            <v-card-title class="bill-title">{{ bill.title }}</v-card-title>
            <v-card-subtitle class="bill-attribute">Status: {{ capitalize(bill.status) }}</v-card-subtitle>
            <v-card-subtitle class="bill-attribute">Status Date: {{ bill.status_last_updated }}</v-card-subtitle>
            <v-card-text class="bill-attribute">
              {{ bill.summary || "Text not available yet." }}
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  data() {
    return {
      bills: []
    };
  },
  beforeMount() {
    this.fetchBills();
  },
  methods: {
    async fetchBills() {
      const response = await axios.get('/bills', { headers: { 'Accept': 'application/json' }, params: { page: 1 } });
      this.bills = response.data.bills;
    },
    capitalize(string) {
      return string.charAt(0).toUpperCase() + string.slice(1).toLowerCase();
    }
  }
}
</script>

<style scoped>
* {
  color: #e0e0e0;
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
}

.bill-card {
  background-color: #505050;
}

#background {
  background-color: #2c2c2c;
  margin: 0;
  padding: 0;
}
</style>