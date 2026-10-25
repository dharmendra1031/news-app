'use client'
import en from "@/utils/locale/en.json";
import { useSelector } from "react-redux";
import { currentTranslationsSelector } from "@/redux/reducers/languageSlice";

// Simple translation hook that reads from en.json only
export const useTranslation = () => {
  const currentTranslations = useSelector(currentTranslationsSelector);

  // Simple translation function
  const t = (label: string): string => {
    // Read from currentTranslations
    if (currentTranslations[label as keyof typeof currentTranslations]) {
      return currentTranslations[label as keyof typeof currentTranslations];
    }

    // Fallback to en.json
    if (en[label as keyof typeof en]) {
      return en[label as keyof typeof en];
    }

    // Return original label if no translation found
    return label;
  };

  return { t };
};
