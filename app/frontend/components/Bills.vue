<template>
  <v-container>
    <v-row>
      <v-col
        v-for="(bill, index) in bills"
        :key="index"
        cols="12"
      >
        <v-card class="mx-auto" max-width="800">
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
.bill-title {
  font-size: 1.5rem;
  font-weight: bold;
  white-space: normal;
  overflow: visible;
}

.bill-attribute {
  font-size: 1rem;
}
</style>