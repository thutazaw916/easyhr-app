import { initializeApp, getApps } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup } from 'firebase/auth';

const firebaseConfig = {
  apiKey: 'AIzaSyCrWjdPN2_E-Mskqmvo8kuigsgfFRAIzbc',
  authDomain: 'easy-hr-23a6a.firebaseapp.com',
  projectId: 'easy-hr-23a6a',
  storageBucket: 'easy-hr-23a6a.firebasestorage.app',
  messagingSenderId: '87983656864',
  appId: '1:87983656864:web:a42025597d10d657aa5ec5',
  measurementId: 'G-4GG1V7BVFM',
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
const auth = getAuth(app);
const googleProvider = new GoogleAuthProvider();

export async function signInWithGoogle() {
  const result = await signInWithPopup(auth, googleProvider);
  const idToken = await result.user.getIdToken();
  return idToken;
}

export { auth };
