import type { Config } from "tailwindcss";
import tailwindcssAnimate from "tailwindcss-animate";

export default {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      screens: {
        "between-1800-2500": {
          min: "1800px",
          max: "2500px",
        },
        "between-1200-1399": {
          min: "1200px",
          max: "1399px",
        },
        "between-1621-1799": {
          min: "1621px",
          max: "1799px",
        },
        "between-1400-1620": {
          min: "1400px",
          max: "1620px",
        },
        "between-1200-1620": {
          min: "1200px",
          max: "1620px",
        },
        "between-992-1199": {
          min: "992px",
          max: "1199px",
        },
        "between-768-991": {
          min: "768px",
          max: "991px",
        },
        "between-576-767": {
          min: "576px",
          max: "767px",
        },
        "between-400-575": {
          min: "400px",
          max: "575px",
        },
        "between-1139-1319": {
          min: "1139px",
          max: "1319px",
        },
        "between-1200-1619": {
          min: "1200px",
          max: "1619px",
        },
        "max-1680": {
          max: "1680px",
        },
        "min-1800": {
          min: "1800px",
        },
        "min-1620": {
          min: "1620px",
        },
        "min-1200": {
          min: "1200px",
        },
        "max-1199": {
          max: "1199px",
        },
        "max-575": {
          max: "575px",
        },
        "max-479": {
          max: "479px",
        },
        "max-399": {
          max: "399px",
        },
        "max-375": {
          max: "375px",
        },
      },
      keyframes: {
        "accordion-down": {
          from: {
            height: "0",
          },
          to: {
            height: "var(--radix-accordion-content-height)",
          },
        },
        "accordion-up": {
          from: {
            height: "var(--radix-accordion-content-height)",
          },
          to: {
            height: "0",
          },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
    container: {
      center: true,
      padding: {
        DEFAULT: "1rem",
        md: "0rem",
      },
    },
  },
  plugins: [tailwindcssAnimate],
} satisfies Config;
