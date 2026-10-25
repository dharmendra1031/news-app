// Loads firebase/auth on demand so it stays out of the initial JS bundle.
export const getFirebaseAuth = async () => {
    const [{ getAuth }, { firebaseApp }] = await Promise.all([import('firebase/auth'), import('./firebaseApp')])
    return getAuth(firebaseApp)
}
