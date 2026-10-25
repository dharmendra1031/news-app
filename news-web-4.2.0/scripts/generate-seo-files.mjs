/**
 * Build-time generator for public/sitemap.xml, public/rssfeed.xml and
 * public/robots.txt.
 *
 * Runs before `next build` (see package.json) so the files are plain static
 * assets — they work the same under `output: 'standalone'` and
 * `output: 'export'`, where API routes / rewrites are unavailable.
 *
 * URLs follow the app's routing: the default language is unprefixed
 * (`/news/foo`), every other language is prefixed (`/hi/news/foo`).
 */
import fs from 'node:fs'
import path from 'node:path'
import nextEnv from '@next/env'

nextEnv.loadEnvConfig(process.cwd())

const PUBLIC_DIR = path.join(process.cwd(), 'public')

const API_PAGE_SIZE = 100 // backend rejects `limit` > 100
const PAGE_CONCURRENCY = 4 // parallel page requests per endpoint once `total` is known
const MAX_PAGES = 2000 // runaway guard (200k items) in case the backend ignores `offset`
const SITEMAP_URL_LIMIT = 50000 // sitemaps.org limit per file
const RSS_ITEM_LIMIT = 50
const REQUEST_TIMEOUT_MS = 20000

// Pages that require login — never worth crawling.
const PRIVATE_ROUTES = [
  '/bookmark',
  '/manage-news',
  '/manage-podcast',
  '/profile-update',
  '/category-preferences',
  '/notification-preferences',
]

// ---------------------------------------------------------------------------
// Env
// ---------------------------------------------------------------------------

const readEnv = () => {
  const required = ['NEXT_PUBLIC_WEB_URL', 'NEXT_PUBLIC_API_URL', 'NEXT_PUBLIC_END_POINT']
  const missing = required.filter((key) => !process.env[key])
  if (missing.length) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`)
  }

  const trimSlash = (value) => value.trim().replace(/\/+$/, '')
  const webUrl = trimSlash(process.env.NEXT_PUBLIC_WEB_URL)
  const apiUrl = trimSlash(process.env.NEXT_PUBLIC_API_URL)

  for (const [key, value] of [['NEXT_PUBLIC_WEB_URL', webUrl], ['NEXT_PUBLIC_API_URL', apiUrl]]) {
    try {
      new URL(value)
    } catch {
      throw new Error(`${key} is not a valid URL: "${value}"`)
    }
  }

  return {
    webUrl,
    apiBase: `${apiUrl}/${process.env.NEXT_PUBLIC_END_POINT.trim().replace(/^\/+|\/+$/g, '')}`,
    title: process.env.NEXT_PUBLIC_TITLE || process.env.NEXT_PUBLIC_WEB_NAME || 'News',
    description: process.env.NEXT_PUBLIC_DESCRIPTION || '',
  }
}

// ---------------------------------------------------------------------------
// API
// ---------------------------------------------------------------------------

const createApi = (apiBase) => {
  const post = async (endpoint, body = {}) => {
    const response = await fetch(`${apiBase}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    })
    const json = await response.json().catch(() => null)
    // The backend answers "No Data Found" with a 404 — that's just an empty list.
    if (response.status === 404) return { total: 0, data: [] }
    if (!response.ok || !json || json.error) {
      throw new Error(`${endpoint} failed (${response.status}): ${json?.message ?? 'invalid response'}`)
    }
    return json.data
  }

  const fetchPage = async (endpoint, body, pageIndex) => {
    const data = await post(endpoint, { ...body, offset: pageIndex * API_PAGE_SIZE, limit: API_PAGE_SIZE })
    const items = Array.isArray(data?.data) ? data.data : Array.isArray(data) ? data : []
    return { items, total: Number(data?.total ?? 0) }
  }

  /**
   * Fetches every item of a `{ total, data: [] }` list endpoint, page by page.
   * The first page reveals `total`; remaining pages are then fetched
   * PAGE_CONCURRENCY at a time. Without a `total`, pages are walked one by one
   * until a short page comes back. A failing page keeps what was already
   * collected; a failing first page degrades to [].
   */
  const postAll = async (endpoint, body = {}) => {
    const items = []
    const label = `${endpoint} ${JSON.stringify(body)}`
    try {
      const first = await fetchPage(endpoint, body, 0)
      items.push(...first.items)
      if (first.items.length < API_PAGE_SIZE) return items

      if (first.total > items.length) {
        const pageCount = Math.min(Math.ceil(first.total / API_PAGE_SIZE), MAX_PAGES)
        for (let start = 1; start < pageCount; start += PAGE_CONCURRENCY) {
          const indexes = Array.from({ length: Math.min(PAGE_CONCURRENCY, pageCount - start) }, (_, i) => start + i)
          const pages = await Promise.all(indexes.map((i) => fetchPage(endpoint, body, i)))
          for (const page of pages) items.push(...page.items)
          if (pages.some((page) => page.items.length < API_PAGE_SIZE)) break
        }
      } else {
        // No usable `total` — walk sequentially until the backend runs dry.
        let previousFirst = JSON.stringify(first.items[0])
        for (let i = 1; i < MAX_PAGES; i++) {
          const page = await fetchPage(endpoint, body, i)
          // Same first row as the previous page means `offset` is being ignored.
          const pageFirst = JSON.stringify(page.items[0])
          if (!page.items.length || pageFirst === previousFirst) break
          previousFirst = pageFirst
          items.push(...page.items)
          if (page.items.length < API_PAGE_SIZE) break
        }
      }
      if (items.length >= MAX_PAGES * API_PAGE_SIZE) console.warn(`  ! ${label}: hit MAX_PAGES, list truncated`)
    } catch (error) {
      console.warn(`  ! ${label}: ${error.message} (kept ${items.length} items)`)
    }
    return items
  }

  return { post, postAll }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const escapeXml = (value) =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')

const cdata = (value) => `<![CDATA[${String(value).replace(/]]>/g, ']]]]><![CDATA[>')}]]>`

const stripHtml = (html) =>
  String(html ?? '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()

const truncate = (text, max) => (text.length > max ? `${text.slice(0, max - 1).trimEnd()}…` : text)

// Backend timezone (settings.system_timezone). Zone-less API dates like
// "2026-09-24 12:03:34" are in this zone, not the build machine's.
let apiTimeZone = 'UTC'

const timeZoneOffsetMs = (utcMs, timeZone) => {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-US', {
      timeZone, hourCycle: 'h23', year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', second: '2-digit',
    }).formatToParts(new Date(utcMs)).map((p) => [p.type, Number(p.value)]),
  )
  return Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second) - utcMs
}

/** Accepts ISO strings and the API's "YYYY-MM-DD[ HH:mm:ss]"; returns a Date or null. */
const parseDate = (value) => {
  if (!value || typeof value !== 'string' || value.startsWith('0000')) return null
  const naive = value.match(/^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$/)
  if (naive) {
    const [, y, mo, d, h = 0, mi = 0, s = 0] = naive.map(Number)
    const asUtc = Date.UTC(y, mo - 1, d, h, mi, s)
    return new Date(asUtc - timeZoneOffsetMs(asUtc, apiTimeZone))
  }
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

const isOn = (flag) => flag === undefined || flag === null || String(flag) === '1'

// Mirrors next.config.ts / src/lib/staticExport.ts.
const isStaticExport = process.env.NEXT_PUBLIC_SEO === 'false'

/** Mirrors src/lib/localizedUrl.ts#withLang. */
const withLang = (href, lang, defaultLang) => {
  const p = href.startsWith('/') ? href : `/${href}`
  if (lang === defaultLang) return p
  return p === '/' ? `/${lang}` : `/${lang}${p}`
}

const writePublicFile = (name, content) => {
  fs.mkdirSync(PUBLIC_DIR, { recursive: true })
  fs.writeFileSync(path.join(PUBLIC_DIR, name), content)
}

// ---------------------------------------------------------------------------
// Route collection
// ---------------------------------------------------------------------------

const collectLanguageRoutes = async (api, lang, settings) => {
  const routes = [] // { path, lastmod?, image? }
  const add = (p, item = {}) => routes.push({ path: p, ...item })
  const lastmodOf = (item) => parseDate(item.updated_at) ?? parseDate(item.date) ?? parseDate(item.created_at)

  // Static listing pages, gated by the same admin toggles the UI uses.
  add('/')
  add('/video-news')
  if (isOn(settings.breaking_news_mode)) add('/breaking-news')
  if (isOn(settings.live_streaming_mode)) add('/live-news')
  if (isOn(settings.e_news_mode)) add('/enews')
  if (isOn(settings.news_buzz_mode)) add('/newsbuzz')
  if (isOn(settings.rss_feed_mode)) add('/rss-feed')

  const byLang = { language_code: lang }
  const [categories, news, breakingNews, videos, tags, pages] = await Promise.all([
    isOn(settings.category_mode) ? api.postAll('get_category', byLang) : [],
    api.postAll('get_news', byLang),
    isOn(settings.breaking_news_mode) ? api.postAll('get_breaking_news', byLang) : [],
    api.postAll('get_videos', byLang),
    api.postAll('get_tag', byLang),
    api.postAll('get_pages', byLang),
  ])

  for (const category of categories) {
    if (!category.slug) continue
    add(`/categories-news/${category.slug}`, { lastmod: lastmodOf(category) })
    if (!isOn(settings.subcategory_mode)) continue
    for (const sub of category.sub_categories ?? []) {
      if (sub.slug) add(`/categories-news/sub-category/${sub.slug}`, { lastmod: lastmodOf(sub) })
    }
  }
  for (const item of news) {
    if (item.slug) add(`/news/${item.slug}`, { lastmod: lastmodOf(item), image: item.image })
  }
  for (const item of breakingNews) {
    if (item.slug) add(`/breaking-news/${item.slug}`, { lastmod: lastmodOf(item), image: item.image })
  }
  for (const item of videos) {
    if (item.slug) add(`/video-news/${item.slug}`, { lastmod: lastmodOf(item), image: item.image })
  }
  for (const tag of tags) {
    if (tag.slug) add(`/tag/${tag.slug}`)
  }
  for (const page of pages) {
    if (page.slug && String(page.status ?? '1') === '1') add(`/more-pages/${page.slug}`)
  }

  return { routes, news }
}

/** Podcasts aren't language-scoped in the API, so they're listed once. */
const collectPodcastRoutes = async (api, settings) => {
  if (!isOn(settings.podcast_mode)) return []
  const podcasts = await api.postAll('get_podcast', { type: 'all' })
  return [
    { path: '/podcast' },
    ...podcasts
      .filter((p) => p.slug)
      .map((p) => ({ path: `/podcast/${p.slug}`, lastmod: parseDate(p.updated_at) ?? parseDate(p.published_at), image: p.image })),
  ]
}

// ---------------------------------------------------------------------------
// Writers
// ---------------------------------------------------------------------------

const renderUrl = ({ loc, lastmod, image }) => {
  const lines = [`    <loc>${escapeXml(loc)}</loc>`]
  if (lastmod) lines.push(`    <lastmod>${lastmod.toISOString()}</lastmod>`)
  if (image) lines.push(`    <image:image><image:loc>${escapeXml(image)}</image:loc></image:image>`)
  return `  <url>\n${lines.join('\n')}\n  </url>`
}

const writeSitemaps = (webUrl, entries) => {
  // Remove sitemaps from a previous, larger run so stale chunks aren't served.
  for (const file of fs.existsSync(PUBLIC_DIR) ? fs.readdirSync(PUBLIC_DIR) : []) {
    if (/^sitemap(-\d+)?\.xml$/.test(file)) fs.rmSync(path.join(PUBLIC_DIR, file))
  }

  const urlset = (chunk) => `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
${chunk.map(renderUrl).join('\n')}
</urlset>
`

  if (entries.length <= SITEMAP_URL_LIMIT) {
    writePublicFile('sitemap.xml', urlset(entries))
    return 1
  }

  const chunks = []
  for (let i = 0; i < entries.length; i += SITEMAP_URL_LIMIT) chunks.push(entries.slice(i, i + SITEMAP_URL_LIMIT))
  const now = new Date().toISOString()
  chunks.forEach((chunk, i) => writePublicFile(`sitemap-${i + 1}.xml`, urlset(chunk)))
  writePublicFile('sitemap.xml', `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${chunks.map((_, i) => `  <sitemap>\n    <loc>${escapeXml(`${webUrl}/sitemap-${i + 1}.xml`)}</loc>\n    <lastmod>${now}</lastmod>\n  </sitemap>`).join('\n')}
</sitemapindex>
`)
  return chunks.length
}

/** Our own news article -> the feed's common item shape. */
const normalizeNewsItem = (item, webUrl, lang, defaultLang) => {
  const link = `${webUrl}${withLang(`/news/${item.slug}`, lang, defaultLang)}`
  return {
    title: item.title,
    link,
    guid: link,
    description: truncate(stripHtml(item.meta_description || item.summarized_description || item.description), 300),
    pubDate: parseDate(item.date) ?? parseDate(item.created_at),
    category: item.category?.category_name,
    author: item.user?.name,
    image: item.image,
  }
}

/** A configured RSS feed source (from get_rss_feed) -> the feed's common item shape. */
const normalizeFeedSource = (source) => ({
  title: source.feed_name,
  link: source.feed_url,
  guid: source.feed_url,
  description: source.category?.category_name ? `RSS source for ${source.category.category_name}` : undefined,
  pubDate: parseDate(source.last_fetched_at) ?? parseDate(source.updated_at) ?? parseDate(source.created_at),
  category: source.category?.category_name,
})

const writeRssFeed = ({ webUrl, title, description }, lang, defaultLang, news, feedSources) => {
  const feedUrl = `${webUrl}/rssfeed.xml`
  const items = [
    ...news.filter((item) => item.slug && item.title).map((item) => normalizeNewsItem(item, webUrl, lang, defaultLang)),
    ...feedSources.filter((source) => source.feed_url && source.feed_name && String(source.status ?? '1') === '1').map(normalizeFeedSource),
  ]
    .sort((a, b) => (b.pubDate?.getTime() ?? 0) - (a.pubDate?.getTime() ?? 0))
    .slice(0, RSS_ITEM_LIMIT)

  const renderItem = (item) => {
    const lines = [
      `      <title>${cdata(item.title)}</title>`,
      `      <link>${escapeXml(item.link)}</link>`,
      `      <guid isPermaLink="true">${escapeXml(item.guid)}</guid>`,
    ]
    if (item.description) lines.push(`      <description>${cdata(item.description)}</description>`)
    if (item.pubDate) lines.push(`      <pubDate>${item.pubDate.toUTCString()}</pubDate>`)
    if (item.category) lines.push(`      <category>${cdata(item.category)}</category>`)
    if (item.author) lines.push(`      <dc:creator>${cdata(item.author)}</dc:creator>`)
    if (item.image) lines.push(`      <media:content url="${escapeXml(item.image)}" medium="image" />`)
    return `    <item>\n${lines.join('\n')}\n    </item>`
  }

  writePublicFile('rssfeed.xml', `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title>${cdata(title)}</title>
    <link>${escapeXml(webUrl)}</link>
    <description>${cdata(description)}</description>
    <language>${escapeXml(lang)}</language>
    <lastBuildDate>${new Date().toUTCString()}</lastBuildDate>
    <atom:link href="${escapeXml(feedUrl)}" rel="self" type="application/rss+xml" />
${items.map(renderItem).join('\n')}
  </channel>
</rss>
`)
  return items.length
}

/** RSS feed sources configured in admin (GET_RSS_FEED). */
const fetchRssFeedSources = async (api, lang) => {
  try {
    return await api.postAll('get_rss_feed', { language_code: lang })
  } catch (error) {
    console.warn(`  ! get_rss_feed: ${error.message}`)
    return []
  }
}

const writeRobots = (webUrl) => {
  const disallow = PRIVATE_ROUTES.flatMap((route) => [`Disallow: ${route}`, `Disallow: /*${route}`])
  writePublicFile('robots.txt', ['User-agent: *', 'Allow: /', ...disallow, '', `Sitemap: ${webUrl}/sitemap.xml`, ''].join('\n'))
}

// ---------------------------------------------------------------------------
// .htaccess (static export only)
// ---------------------------------------------------------------------------

const LANG_PAGES_DIR = path.join(process.cwd(), 'src', 'pages', '[langCode]')
const LOCALE_RE = '[a-z]{2}(?:-[A-Z]{2})?'

/**
 * Every page under src/pages/[langCode] exports once, as a literal
 * "[langCode]/..." file shared by all languages (e.g. /ar/news/foo ->
 * out/[langCode]/news/[slug].html). Returns { segments, file } per page,
 * where segments excludes the leading [langCode].
 */
const collectExportRoutes = (dir = LANG_PAGES_DIR, segments = []) => {
  const routes = []
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      routes.push(...collectExportRoutes(path.join(dir, entry.name), [...segments, entry.name]))
      continue
    }
    if (!/\.(tsx|ts|jsx|js)$/.test(entry.name)) continue
    const name = entry.name.replace(/\.[^.]+$/, '')
    const routeSegments = name === 'index' ? segments : [...segments, name]
    routes.push({ segments: routeSegments, file: `/${['[langCode]', ...routeSegments].join('/')}.html` })
  }
  return routes
}

// Apache takes the first matching rule, so a static segment must beat a
// dynamic one at the same position (categories-news/sub-category/x before
// categories-news/[slug]/[cateSlug]).
const compareRoutes = (a, b) => {
  const isDynamic = (segment) => segment.startsWith('[')
  for (let i = 0; i < Math.min(a.segments.length, b.segments.length); i++) {
    const diff = Number(isDynamic(a.segments[i])) - Number(isDynamic(b.segments[i]))
    if (diff) return diff
  }
  return b.segments.length - a.segments.length
}

const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

const writeHtaccess = (defaultLang) => {
  const routes = collectExportRoutes().sort(compareRoutes)
  const routeRules = routes.map(({ segments, file }) => {
    const pattern = segments.map((s) => (s.startsWith('[') ? '[^/]+' : escapeRegex(s))).join('/')
    const source = pattern ? `(?:${LOCALE_RE}/)?${pattern}` : `(?:${LOCALE_RE})?`
    return `RewriteRule ^${source}$ ${file} [END]`
  })
  const defaultLangRe = escapeRegex(defaultLang)

  writePublicFile('.htaccess', `# Apache config for the static export (NEXT_PUBLIC_SEO=false -> npm run export -> out/).
# Generated by scripts/generate-seo-files.mjs on every build — edit that, not this file.
#
# Stands in for src/proxy.ts, which doesn't run in a static export: the
# default language ("${defaultLang}") is served at bare URLs, other languages
# under their prefix. The client router does the same mapping via the
# rewrites in next.config.ts.

Options -Indexes -MultiViews
DirectorySlash Off

# Long cache for static assets.
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/png "access plus 30 days"
  ExpiresByType image/jpeg "access plus 30 days"
  ExpiresByType image/gif "access plus 30 days"
  ExpiresByType image/webp "access plus 30 days"
  ExpiresByType image/avif "access plus 30 days"
  ExpiresByType image/svg+xml "access plus 30 days"
  ExpiresByType image/x-icon "access plus 30 days"
  ExpiresByType font/woff2 "access plus 1 year"
</IfModule>
RewriteEngine On
RewriteBase /

# Pages still statically export a (disabled) getServerSideProps, so Next's
# client router fetches /_next/data/<build>/<path>.json on every link click
# and hard-reloads when it 404s. Answer them all with empty page props, the
# same props the exported HTML was built with.
RewriteRule ^_next/data/.+\\.json$ /${EXPORT_PAGE_DATA_FILE} [END]

# Real files (/_next/..., images, sitemap.xml, ...).
RewriteCond %{REQUEST_FILENAME} -f
RewriteRule ^ - [END]

RewriteRule ^(.+)/$ /$1 [R=301,L]

# Explicit default-language prefix -> bare URL ("/${defaultLang}/podcast" -> "/podcast").
RewriteRule ^${defaultLangRe}(?:/(.*))?$ /$1 [R=301,L]

# Bare URL + "lang" cookie for another language -> that language's URL.
RewriteCond %{HTTP_COOKIE} (?:^|;\\s*)lang=(${LOCALE_RE})(?:;|$)
RewriteCond %1 !=${defaultLang}
RewriteRule ^$ /%1 [R=302,L]
RewriteCond $1 !^${LOCALE_RE}(?:/|$)
RewriteCond %{HTTP_COOKIE} (?:^|;\\s*)lang=(${LOCALE_RE})(?:;|$)
RewriteCond %1 !=${defaultLang}
RewriteRule ^([^.]+)$ /%1/$1 [R=302,L]

# Bare or language-prefixed URL -> the page's shared export file.
${routeRules.join('\n')}

ErrorDocument 404 /404.html
`)
}

const EXPORT_PAGE_DATA_FILE = 'export-page-data.json'

const writeExportPageData = () => writePublicFile(EXPORT_PAGE_DATA_FILE, JSON.stringify({ pageProps: {} }))

const removeStaticExportFiles = () => {
  for (const name of ['.htaccess', EXPORT_PAGE_DATA_FILE]) {
    const file = path.join(PUBLIC_DIR, name)
    if (fs.existsSync(file)) fs.rmSync(file)
  }
}

// Fixed icon set — these files live in `public/` (not admin-configurable),
// so they're declared once here rather than derived per build.
const MANIFEST_ICONS = [
  { src: '/favicon-16x16.png', sizes: '16x16', type: 'image/png', purpose: 'any' },
  { src: '/favicon-32x32.png', sizes: '32x32', type: 'image/png', purpose: 'any' },
  { src: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png', purpose: 'any' },
  { src: '/android-chrome-192x192.png', sizes: '192x192', type: 'image/png', purpose: 'any maskable' },
  { src: '/android-chrome-512x512.png', sizes: '512x512', type: 'image/png', purpose: 'any maskable' },
]

/**
 * PWA manifest.json — name/description/theme/lang generated from live
 * settings rather than hardcoded, so they always match whatever admin has
 * configured. Icons are the fixed local set above.
 */
const writeManifest = (env, settings) => {
  const webSetting = settings?.web_setting ?? {}
  const name = webSetting.web_name || env.title
  const themeColor = process.env.NEXT_PUBLIC_LOADER_COLOR || '#EE2934'

  writePublicFile('manifest.json', JSON.stringify({
    name,
    short_name: name,
    description: webSetting.web_footer_description || env.description,
    start_url: '/',
    scope: '/',
    display: 'standalone',
    orientation: 'portrait',
    theme_color: themeColor,
    background_color: themeColor,
    lang: settings?.default_language?.code || 'en',
    dir: settings?.default_language?.isRTL === 1 ? 'rtl' : 'ltr',
    icons: MANIFEST_ICONS,
  }, null, 2))
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const main = async () => {
  const env = readEnv()
  const api = createApi(env.apiBase)

  // robots.txt only needs the env, so write it even if the API is down.
  writeRobots(env.webUrl)

  const settings = await api.post('get_settings')
  const defaultLang = settings?.default_language?.code
  if (!defaultLang) throw new Error('Default language code missing from get_settings response')

  writeManifest(env, settings)
  console.log('✓ manifest.json')

  if (isStaticExport) {
    writeHtaccess(defaultLang)
    writeExportPageData()
    console.log('✓ .htaccess')
  } else {
    removeStaticExportFiles()
  }

  try {
    if (settings.system_timezone) {
      new Intl.DateTimeFormat('en-US', { timeZone: settings.system_timezone })
      apiTimeZone = settings.system_timezone
    }
  } catch {
    console.warn(`  ! Unknown system_timezone "${settings.system_timezone}" — treating API dates as UTC`)
  }

  let languages = [defaultLang]
  try {
    const list = await api.post('get_languages_list')
    const active = (list?.data ?? []).filter((l) => l.code && String(l.status) === '1').map((l) => l.code)
    languages = [defaultLang, ...active.filter((code) => code !== defaultLang)]
  } catch (error) {
    console.warn(`  ! get_languages_list: ${error.message} — using default language only`)
  }
  console.log(`Languages: ${languages.join(', ')} (default: ${defaultLang})`)

  const [perLanguage, podcastRoutes, feedSources] = await Promise.all([
    Promise.all(languages.map((lang) => collectLanguageRoutes(api, lang, settings))),
    collectPodcastRoutes(api, settings),
    fetchRssFeedSources(api, defaultLang),
  ])

  const seen = new Set()
  const entries = []
  const push = (lang, route) => {
    const loc = `${env.webUrl}${withLang(route.path, lang, defaultLang)}`
    if (seen.has(loc)) return
    seen.add(loc)
    entries.push({ loc, lastmod: route.lastmod ?? null, image: route.image || null })
  }
  languages.forEach((lang, i) => perLanguage[i].routes.forEach((route) => push(lang, route)))
  podcastRoutes.forEach((route) => push(defaultLang, route))

  const files = writeSitemaps(env.webUrl, entries)
  console.log(`✓ sitemap.xml — ${entries.length} URLs${files > 1 ? ` across ${files} files` : ''}`)

  const rssCount = writeRssFeed(env, defaultLang, defaultLang, perLanguage[0].news, feedSources)
  console.log(`✓ rssfeed.xml — ${rssCount} items`)
  console.log('✓ robots.txt')
}

main().catch((error) => {
  console.error(`✗ SEO file generation failed: ${error.message}`)
  process.exit(1)
})
