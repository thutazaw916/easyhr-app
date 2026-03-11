'use client';
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import Cookies from 'js-cookie';
import { login as apiLogin, googleLogin as apiGoogleLogin, getMe } from './api';
import { signInWithGoogle } from './firebase';

interface User {
  id: string;
  first_name: string;
  last_name?: string;
  email: string;
  phone: string;
  role: string;
  company_id: string;
  company?: any;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  loginWithGoogle: () => Promise<any>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType>({} as AuthContextType);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = Cookies.get('token');
    if (token) {
      getMe().then(res => { setUser(res.data); setLoading(false); })
        .catch(() => { Cookies.remove('token'); setLoading(false); });
    } else {
      setLoading(false);
    }
  }, []);

  const login = async (email: string, password: string) => {
    const res = await apiLogin(email, password);
    const { access_token, user: userData } = res.data;
    Cookies.set('token', access_token, { expires: 7 });
    const me = await getMe();
    setUser(me.data);
  };

  const loginWithGoogle = async () => {
    const idToken = await signInWithGoogle();
    const res = await apiGoogleLogin(idToken);
    const { access_token, needs_onboarding } = res.data;
    if (needs_onboarding) {
      return { needs_onboarding: true, google_user: res.data.google_user };
    }
    Cookies.set('token', access_token, { expires: 7 });
    const me = await getMe();
    setUser(me.data);
    return { needs_onboarding: false };
  };

  const logout = () => {
    Cookies.remove('token');
    setUser(null);
    window.location.href = '/login';
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, loginWithGoogle, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
