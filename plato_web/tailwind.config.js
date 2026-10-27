/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./*.html",
    "./*.js",
    "./src/**/*.{js,ts,jsx,tsx,html}",
  ],
  theme: {
    extend: {
      colors: {
        // Plato Gym Colors from Flutter Theme
        plato: {
          bg: '#121212',
          surface: '#1E1E1E',
          gold: '#FFC107', 
          success: '#4CAF50',
          warning: '#FF9800',
          teal: '#00BFA5',
          purple: '#7C4DFF',
          primary: '#1E88E5',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
