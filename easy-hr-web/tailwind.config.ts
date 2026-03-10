import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#2563EB', 50: '#EFF6FF', 100: '#DBEAFE', 200: '#BFDBFE', 300: '#93C5FD', 400: '#60A5FA', 500: '#3B82F6', 600: '#2563EB', 700: '#1D4ED8', 800: '#1E40AF', 900: '#1E3A8A' },
        accent: '#10B981',
        success: '#10B981',
        warning: '#F59E0B',
        danger: '#EF4444',
        info: '#6366F1',
        dark: {
          bg: '#000000',
          card: '#1C1C1E',
          elevated: '#2C2C2E',
          border: '#38383A',
          divider: '#2C2C2E',
          text: '#FFFFFF',
          secondary: '#8E8E93',
        },
      },
    },
  },
  plugins: [],
};
export default config;
