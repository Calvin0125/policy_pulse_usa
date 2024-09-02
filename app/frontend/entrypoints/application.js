import { createApp } from 'vue'
import Bills from '../components/Bills.vue'
import { createVuetify } from 'vuetify';
import 'vuetify/styles';
import * as components from 'vuetify/components';
import * as directives from 'vuetify/directives';
import '@mdi/font/css/materialdesignicons.css';

const vuetify = createVuetify({
  components,
  directives,
});

document.addEventListener('DOMContentLoaded', () => {
  const app = createApp(Bills);
  app.use(vuetify);
  app.mount('#app');
});