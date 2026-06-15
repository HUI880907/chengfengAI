/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        ink: {
          900: '#050A18',
          800: '#0B1F3A',
          700: '#13294B',
          600: '#1E3A5F',
          500: '#2A4A7A',
        },
        neon: {
          cyan: '#00E5FF',
          blue: '#3B82F6',
          purple: '#A855F7',
        },
        success: '#10B981',
        warning: '#F59E0B',
        danger: '#EF4444',
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'Menlo', 'monospace'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        'glow-cyan': '0 0 25px rgba(0, 229, 255, 0.35)',
        'glow-blue': '0 0 25px rgba(59, 130, 246, 0.35)',
        'card': '0 10px 40px -15px rgba(0, 0, 0, 0.6)',
      },
      backgroundImage: {
        'grid-pattern':
          'linear-gradient(rgba(0,229,255,0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(0,229,255,0.05) 1px, transparent 1px)',
        'radial-hero':
          'radial-gradient(ellipse at top, rgba(0,229,255,0.18), transparent 60%)',
      },
      backgroundSize: {
        'grid-size': '40px 40px',
      },
      keyframes: {
        pulseGlow: {
          '0%,100%': { boxShadow: '0 0 0 0 rgba(0,229,255,0.45)' },
          '50%': { boxShadow: '0 0 30px 8px rgba(0,229,255,0.18)' },
        },
        shimmer: {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(100%)' },
        },
        fadeUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
      animation: {
        'pulse-glow': 'pulseGlow 2.4s ease-in-out infinite',
        shimmer: 'shimmer 2.2s ease-in-out infinite',
        'fade-up': 'fadeUp 0.6s ease-out forwards',
      },
    },
  },
  plugins: [],
}
