'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-black">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary text-white text-2xl font-bold mb-4">
            HR
          </div>
          <h1 className="text-3xl font-bold text-white">Easy HR</h1>
          <p className="text-[#8E8E93] mt-1">Admin Dashboard</p>
        </div>

        <div className="bg-[#1C1C1E] rounded-2xl shadow-xl p-8 border border-[#38383A]">
          <h2 className="text-xl font-semibold text-white mb-6">Sign in to your account</h2>

          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-500/15 text-red-400 text-sm">{error}</div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-[#8E8E93] mb-1">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white placeholder-[#8E8E93] focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition"
                placeholder="admin@company.com"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-[#8E8E93] mb-1">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white placeholder-[#8E8E93] focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition"
                placeholder="Enter your password"
                required
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-primary hover:bg-primary-700 text-white font-semibold rounded-xl transition disabled:opacity-50"
            >
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>

          <p className="text-center text-sm text-[#8E8E93] mt-4">
            Don&apos;t have an account?{' '}
            <a href="/signup" className="text-primary font-semibold hover:underline">Sign Up</a>
          </p>
        </div>

        <p className="text-center text-[#8E8E93] text-sm mt-6">
          Easy HR &copy; 2026 - Myanmar SME HR Platform
        </p>
      </div>
    </div>
  );
}
