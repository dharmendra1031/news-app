"use client";

import DOMPurify from "dompurify";
import { useMemo } from "react";

// ✅ Use the correct type import instead of DOMPurify.Config namespace
import type { Config } from "dompurify";

const DOMPURIFY_CONFIG: Config = {
  ALLOWED_TAGS: [
    "p", "br", "b", "i", "em", "strong", "u", "s", "ul", "ol", "li",
    "a", "h1", "h2", "h3", "h4", "h5", "h6", "blockquote", "span", "div",
    "table", "thead", "tbody", "tr", "th", "td", "img",
  ],
  ALLOWED_ATTR: [
    "href", "target", "rel",
    "src", "alt", "width", "height",
    "class",
  ],
  FORBID_ATTR: ["style", "onerror", "onload"],
  ALLOW_DATA_ATTR: false,
};

if (typeof window !== "undefined") {
  DOMPurify.addHook("afterSanitizeAttributes", (node) => {
    if (node.tagName === "A") {
      node.setAttribute("rel", "noopener noreferrer");
    }
  });
}

const RichTextContent = ({ content, className }: { content: string, className?: string }) => {
  const cleanedContent = useMemo(() => {
    if (!content) return "";

    let normalized = content
      .replace(/&nbsp;/g, " ")
      .replace(/word-break:\s*break-all;?/gi, "");

    const isPlainText = !/<[a-z][\s\S]*>/i.test(normalized);
    if (isPlainText) {
      normalized = normalized
        .split(/\n\n+/)
        .map(p => `<p>${p.replace(/\n/g, "<br>")}</p>`)
        .join("");
    }

    if (typeof window === "undefined") return normalized;

    return DOMPurify.sanitize(normalized, DOMPURIFY_CONFIG);
  }, [content]);

  return (
    <div
      className={`rich-text-content break-words whitespace-normal leading-relaxed w-full ${className}`}
      dangerouslySetInnerHTML={{ __html: cleanedContent }}
    />
  );
};

export default RichTextContent;