const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'
const GEMINI_MODEL = 'gemini-3.1-flash-lite'

const callGeminiAPI = async (apiKey: string, prompt: string) => {
    const response = await fetch(`${GEMINI_API_URL}/${GEMINI_MODEL}:generateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    })

    if (!response.ok) {
        const errorData = await response.json().catch(() => null)
        throw new Error(errorData?.error?.message || 'Failed to generate content')
    }

    const data = await response.json()
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text
    if (!text) throw new Error('Gemini returned no content')
    return text as string
}

interface GenerateContentParams {
    apiKey: string
    prompt?: string
    title: string
    category?: string | null
    language: string
    languageCode: string
    contentType: string
}

export const generateContent = async ({ apiKey, prompt, title, category, language, languageCode, contentType }: GenerateContentParams) => {
    let fullPrompt = `You are a skilled news article writer. Write a comprehensive news article description/content for the title: '${title}' in ${language} language. Create engaging, informative content suitable for a ${contentType} article. Include relevant details and maintain a professional journalistic tone.

CRITICAL: Return ONLY the plain text content. Do NOT include any markdown formatting, code blocks, HTML tags, or syntax wrappers like \`\`\`html or \`\`\`. Just return the raw article content as plain text.`

    if (category) fullPrompt += `\n\nCategory: ${category}`
    if (language && languageCode) fullPrompt += `\n\nIMPORTANT: Generate all content in ${language} language (${languageCode}). The response MUST be in ${language}.`
    if (prompt) fullPrompt += `\n\nAdditional Request: ${prompt}`

    return callGeminiAPI(apiKey, fullPrompt)
}

interface GeneratedMetaInfo {
    meta_title: string
    meta_description: string
    meta_keywords: string
    slug: string
}

interface GenerateMetaInfoParams {
    apiKey: string
    title: string
    language: string
    languageCode: string
}

export const generateMetaInfo = async ({ apiKey, title, language, languageCode }: GenerateMetaInfoParams): Promise<GeneratedMetaInfo> => {
    const languageInstruction = language && languageCode
        ? `\n\nIMPORTANT: Generate all content in ${language} language (${languageCode}). The response MUST be in the same language as the title.`
        : ''

    const prompt = `You are an SEO expert. Generate meta title, description, keywords, and a slug for this news article titled: "${title}".${languageInstruction}

Return ONLY a JSON object with these fields:
- meta_title: an SEO-friendly title (max 60 chars)
- meta_description: an engaging description (between 50-160 chars)
- meta_keywords: comma-separated keywords
- slug: URL-friendly version of the title (avoid other languages only in english)

The response must be valid JSON format with these exact field names. Do not include any explanation or additional text.`

    const responseText = (await callGeminiAPI(apiKey, prompt)).trim()

    try {
        return JSON.parse(responseText)
    } catch {
        const jsonMatch = responseText.match(/\{[\s\S]*\}/)
        if (jsonMatch) {
            try {
                return JSON.parse(jsonMatch[0])
            } catch {
                // fall through to the heuristic fallback below
            }
        }
        return {
            meta_title: title,
            meta_description: `Read about ${title} in our latest news article.`,
            meta_keywords: title.toLowerCase().split(' ').join(','),
            slug: title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, ''),
        }
    }
}

export const summarizeDescription = async (apiKey: string, description: string, language = 'English', languageCode = 'en') => {
    const cleanContent = description.replace(/<[^>]*>/g, '').trim()
    if (!cleanContent) return ''

    const prompt = `You are a skilled content summarizer. Create a concise and engaging summary of the following news content.

Content to summarize: "${cleanContent}"

Instructions:
- Create a summary that is 10-15 sentences long (approximately 200-250 words)
- Maintain the key facts and main points
- Use clear, professional language appropriate for a news website
- Focus on the most important information
- Make it engaging for readers
- Return only the summary text, no additional explanations

${language && languageCode ? `IMPORTANT: Generate the summary in ${language} language (${languageCode}).` : ''}

Summary:`

    try {
        const summarizedText = (await callGeminiAPI(apiKey, prompt)).trim()
        return summarizedText.replace(/^["']|["']$/g, '').trim()
    } catch (error) {
        console.error('Content summarization error:', error)
        return `${cleanContent.substring(0, 150)}...`
    }
}
