import { createApp } from 'vue'
import Bills from '../components/Bills.vue'

document.addEventListener('DOMContentLoaded', () => {
  const app = createApp(Bills)
  app.mount('#app')
})