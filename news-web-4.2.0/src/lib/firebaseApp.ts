import { initializeApp, getApps, getApp } from 'firebase/app'

const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_APP_ID,
    measurementId: process.env.NEXT_PUBLIC_MEASUREMENT_ID,
}

// Import this only from code that needs Firebase (login forms, push
// notifications, logout) — keeping it out of the shared bundle is the point.
export const firebaseApp = getApps().length ? getApp() : initializeApp(firebaseConfig)
