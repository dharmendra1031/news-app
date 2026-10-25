import { getStore } from '@/redux/store'

export const isLogin = () => {
  return getStore().getState().user.isLogin;
};

export const currentLangCode = () => {
  return getStore().getState().languages.currentLanguage.code;
};

export const defaultLanguageCode = () => {
  return getStore().getState().settings.data?.default_language?.code;
};

export const formatDuration = (seconds?: number) => {
  if (!seconds || seconds < 0) return '0s';

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = Math.floor(seconds % 60);

  const parts: string[] = [];

  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  if (remainingSeconds > 0 || parts.length === 0) {
    parts.push(`${remainingSeconds}s`);
  }

  return parts.join(' ');
};

// Strips markup so the text can be handed to speech synthesis. DOMParser is
// browser-only, so this returns '' during SSR.
export const extractTextFromHTML = (html?: string | null) => {
  if (!html || typeof window === 'undefined') return '';
  return new DOMParser().parseFromString(html, 'text/html').body.textContent || '';
};

export const truncateText = (text?: string, maxLength = 100) => {
  if (!text) return '';
  return text.length > maxLength ? `${text.slice(0, maxLength).trimEnd()}...` : text;
};

export const formatPlayerTime = (seconds?: number) => {
  if (!seconds || seconds < 0 || !isFinite(seconds)) return '00:00';

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = Math.floor(seconds % 60);

  const mm = String(minutes).padStart(2, '0');
  const ss = String(remainingSeconds).padStart(2, '0');

  return hours > 0 ? `${hours}:${mm}:${ss}` : `${mm}:${ss}`;
};

export const formatShortDate = (date?: string) => {
  if (!date) return '';

  const parsedDate = new Date(date);
  if (isNaN(parsedDate.getTime())) return '';

  return parsedDate.toLocaleDateString('en-US', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
};

export const formatTimeAgo = (date?: string | null) => {
  if (!date) return '';

  const parsedDate = new Date(date);
  if (isNaN(parsedDate.getTime())) return '';

  const seconds = Math.floor((Date.now() - parsedDate.getTime()) / 1000);
  if (seconds < 60) return 'Just now';

  const units: [number, string][] = [
    [31536000, 'year'],
    [2592000, 'month'],
    [86400, 'day'],
    [3600, 'hour'],
    [60, 'min'],
  ];

  for (const [unitSeconds, label] of units) {
    const value = Math.floor(seconds / unitSeconds);
    if (value >= 1) return `${value} ${label}${value > 1 ? 's' : ''} ago`;
  }

  return 'Just now';
};

export const formatViewCount = (count?: number) => {
  if (!count) return '0'
  if (count >= 1000000) return `${(count / 1000000).toFixed(count % 1000000 === 0 ? 0 : 1)}m`
  if (count >= 1000) return `${(count / 1000).toFixed(count % 1000 === 0 ? 0 : 1)}k`
  return `${count}`
}

export const getAuthErrorMessage = (errorCode?: string) => {
  switch (errorCode) {
    case 'auth/admin-restricted-operation':
      return 'Admin Only Operation';
    case 'auth/already-initialized':
      return 'Already Initialized';
    case 'auth/app-not-authorized':
      return 'App Not Authorized';
    case 'auth/app-not-installed':
      return 'App Not Installed';
    case 'auth/argument-error':
      return 'Argument Error';
    case 'auth/captcha-check-failed':
      return 'Captcha Check Failed';
    case 'auth/code-expired':
      return 'Code Expired';
    case 'auth/cordova-not-ready':
      return 'Cordova Not Ready';
    case 'auth/cors-unsupported':
      return 'CORS Unsupported';
    case 'auth/credential-already-in-use':
      return 'Credential Already In Use';
    case 'auth/custom-token-mismatch':
      return 'Credential Mismatch';
    case 'auth/requires-recent-login':
      return 'Credential Too Old, Login Again';
    case 'auth/dependent-sdk-initialized-before-auth':
      return 'Dependent SDK Initialized Before Auth';
    case 'auth/dynamic-link-not-activated':
      return 'Dynamic Link Not Activated';
    case 'auth/email-change-needs-verification':
      return 'Email Change Needs Verification';
    case 'auth/email-already-in-use':
      return 'Email Already In Use';
    case 'auth/emulator-config-failed':
      return 'Emulator Config Failed';
    case 'auth/expired-action-code':
      return 'Expired OOB Code';
    case 'auth/cancelled-popup-request':
      return 'Expired Popup Request';
    case 'auth/internal-error':
      return 'Internal Error';
    case 'auth/invalid-api-key':
      return 'Invalid API Key';
    case 'auth/invalid-app-credential':
      return 'Invalid App Credential';
    case 'auth/invalid-app-id':
      return 'Invalid App ID';
    case 'auth/invalid-user-token':
      return 'Invalid Auth';
    case 'auth/invalid-auth-event':
      return 'Invalid Auth Event';
    case 'auth/invalid-cert-hash':
      return 'Invalid Cert Hash';
    case 'auth/invalid-verification-code':
      return 'Invalid Code';
    case 'auth/invalid-continue-uri':
      return 'Invalid Continue URI';
    case 'auth/invalid-cordova-configuration':
      return 'Invalid Cordova Configuration';
    case 'auth/invalid-custom-token':
      return 'Invalid Custom Token';
    case 'auth/invalid-dynamic-link-domain':
      return 'Invalid Dynamic Link Domain';
    case 'auth/invalid-email':
      return 'Invalid Email';
    case 'auth/invalid-emulator-scheme':
      return 'Invalid Emulator Scheme';
    case 'auth/invalid-credential':
      return 'Invalid IDP Response / Invalid Login Credentials';
    case 'auth/invalid-message-payload':
      return 'Invalid Message Payload';
    case 'auth/invalid-multi-factor-session':
      return 'Invalid MFA Session';
    case 'auth/invalid-oauth-client-id':
      return 'Invalid OAuth Client ID';
    case 'auth/invalid-oauth-provider':
      return 'Invalid OAuth Provider';
    case 'auth/invalid-action-code':
      return 'Invalid OOB Code';
    case 'auth/unauthorized-domain':
      return 'Invalid Origin';
    case 'auth/wrong-password':
      return 'Invalid Password';
    case 'auth/invalid-persistence-type':
      return 'Invalid Persistence';
    case 'auth/invalid-phone-number':
      return 'Invalid Phone Number';
    case 'auth/invalid-provider-id':
      return 'Invalid Provider ID';
    case 'auth/invalid-recaptcha-action':
      return 'Invalid Recaptcha Action';
    case 'auth/invalid-recaptcha-token':
      return 'Invalid Recaptcha Token';
    case 'auth/invalid-recaptcha-version':
      return 'Invalid Recaptcha Version';
    case 'auth/invalid-recipient-email':
      return 'Invalid Recipient Email';
    case 'auth/invalid-req-type':
      return 'Invalid Req Type';
    case 'auth/invalid-sender':
      return 'Invalid Sender';
    case 'auth/invalid-verification-id':
      return 'Invalid Session Info';
    case 'auth/invalid-tenant-id':
      return 'Invalid Tenant ID';
    case 'auth/multi-factor-info-not-found':
      return 'MFA Info Not Found';
    case 'auth/multi-factor-auth-required':
      return 'MFA Required';
    case 'auth/missing-android-pkg-name':
      return 'Missing Android Package Name';
    case 'auth/missing-app-credential':
      return 'Missing App Credential';
    case 'auth/auth-domain-config-required':
      return 'Missing Auth Domain';
    case 'auth/missing-client-type':
      return 'Missing Client Type';
    case 'auth/missing-verification-code':
      return 'Missing Code';
    case 'auth/missing-continue-uri':
      return 'Missing Continue URI';
    case 'auth/missing-iframe-start':
      return 'Missing Iframe Start';
    case 'auth/missing-ios-bundle-id':
      return 'Missing iOS Bundle ID';
    case 'auth/missing-multi-factor-info':
      return 'Missing MFA Info';
    case 'auth/missing-multi-factor-session':
      return 'Missing MFA Session';
    case 'auth/missing-or-invalid-nonce':
      return 'Missing or Invalid Nonce';
    case 'auth/missing-phone-number':
      return 'Missing Phone Number';
    case 'auth/missing-recaptcha-token':
      return 'Missing Recaptcha Token';
    case 'auth/missing-recaptcha-version':
      return 'Missing Recaptcha Version';
    case 'auth/missing-verification-id':
      return 'Missing Session Info';
    case 'auth/app-deleted':
      return 'Module Destroyed';
    case 'auth/account-exists-with-different-credential':
      return 'Need Confirmation';
    case 'auth/network-request-failed':
      return 'Network Request Failed';
    case 'auth/no-auth-event':
      return 'No Auth Event';
    case 'auth/no-such-provider':
      return 'No Such Provider';
    case 'auth/null-user':
      return 'Null User';
    case 'auth/operation-not-allowed':
      return 'Operation Not Allowed';
    case 'auth/operation-not-supported-in-this-environment':
      return 'Operation Not Supported';
    case 'auth/popup-blocked':
      return 'Popup Blocked';
    case 'auth/popup-closed-by-user':
      return 'Popup Closed By User';
    case 'auth/provider-already-linked':
      return 'Provider Already Linked';
    case 'auth/quota-exceeded':
      return 'Quota Exceeded';
    case 'auth/recaptcha-not-enabled':
      return 'Recaptcha Not Enabled';
    case 'auth/redirect-cancelled-by-user':
      return 'Redirect Cancelled By User';
    case 'auth/redirect-operation-pending':
      return 'Redirect Operation Pending';
    case 'auth/rejected-credential':
      return 'Rejected Credential';
    case 'auth/second-factor-already-in-use':
      return 'Second Factor Already Enrolled';
    case 'auth/maximum-second-factor-count-exceeded':
      return 'Second Factor Limit Exceeded';
    case 'auth/tenant-id-mismatch':
      return 'Tenant ID Mismatch';
    case 'auth/timeout':
      return 'Timeout';
    case 'auth/user-token-expired':
      return 'Token Expired';
    case 'auth/too-many-requests':
      return 'Too Many Attempts, Try Later';
    case 'auth/unauthorized-continue-uri':
      return 'Unauthorized Domain';
    case 'auth/unsupported-first-factor':
      return 'Unsupported First Factor';
    case 'auth/unsupported-persistence-type':
      return 'Unsupported Persistence';
    case 'auth/unsupported-tenant-operation':
      return 'Unsupported Tenant Operation';
    case 'auth/unverified-email':
      return 'Unverified Email';
    case 'auth/user-cancelled':
      return 'User Cancelled';
    case 'auth/user-not-found':
      return 'User Not Found';
    case 'auth/user-disabled':
      return 'User Disabled';
    case 'auth/user-mismatch':
      return 'User Mismatch';
    case 'auth/user-signed-out':
      return 'User Signed Out';
    case 'auth/weak-password':
      return 'Weak Password';
    case 'auth/web-storage-unsupported':
      return 'Web Storage Unsupported';
    default:
      return 'Unknown Error';
  }
};

export const webName = () => {
  return process.env.NEXT_PUBLIC_WEB_NAME || 'News'
}

/** Current document text direction — 'rtl' for RTL languages, 'ltr' otherwise. */
export const getDirection = (): 'ltr' | 'rtl' => {
  if (typeof document !== 'undefined') {
    return (document.documentElement.dir as 'ltr' | 'rtl') || 'ltr'
  }
  return 'ltr'
}

/** Lowercases, strips non `[a-z0-9-]` chars, and collapses/trims dashes. */
export const slugGenerator = (value?: string | null): string => {
  if (!value) return ''
  return value
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+/, '')
    .replace(/-+$/, '')
}

export const validateSlugFormat = (slug?: string | null): boolean => {
  if (!slug) return false
  return /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)
}
