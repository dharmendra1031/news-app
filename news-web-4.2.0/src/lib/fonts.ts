import { Zilla_Slab } from "next/font/google";

// Only the weights the UI uses (font-normal/medium/semibold/bold). Each
// weight/style is a separate font file, and every late-arriving one swaps in
// and shifts layout. Italic is left to the browser's synthesized oblique.
export const primaryFont = Zilla_Slab({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
  variable: "--font-primary",
});
