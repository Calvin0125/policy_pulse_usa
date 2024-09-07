# README
# Policy Pulse USA

Policy Pulse USA is a free website that provides users with unbiased summaries of U.S. federal laws that are in process. You can visit it at https://www.policypulseusa.com

## Technologies Used
- **Ruby on Rails**: Backend framework
- **Vite**: Asset bundler and development server
- **Vue.js**: Frontend framework
- **Vuetify**: UI library for Vue.js
- **AWS**: Hosting platform

## How It Works
- **LegiScan API**: Provides data on current U.S. laws.
- **OpenAI API**: Generates summaries of the full text of each law once it is available.
- **CreateAndUpdateBillsJob**: Runs daily to fetch new laws as well as updates to existing laws.

## License

This project is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/)