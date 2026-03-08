'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { companySignUp, verifyCompany, setPassword } from '@/lib/api';

const businessTypes = [
  { value: 'manufacturing', label: 'Manufacturing' },
  { value: 'retail', label: 'Retail' },
  { value: 'fnb', label: 'Food & Beverage' },
  { value: 'service', label: 'Service' },
  { value: 'technology', label: 'Technology' },
  { value: 'construction', label: 'Construction' },
  { value: 'education', label: 'Education' },
  { value: 'healthcare', label: 'Healthcare' },
  { value: 'other', label: 'Other' },
];

export default function SignUpPage() {
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Step 1: Company info
  const [companyName, setCompanyName] = useState('');
  const [companyNameMm, setCompanyNameMm] = useState('');
  const [businessType, setBusinessType] = useState('retail');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [city, setCity] = useState('');

  // Step 2: Verify
  const [verificationCode, setVerificationCode] = useState('');
  const [devCode, setDevCode] = useState('');

  // Step 3: Set password
  const [ownerName, setOwnerName] = useState('');
  const [ownerPhone, setOwnerPhone] = useState('');
  const [password, setPasswordVal] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const handleStep1 = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await companySignUp({
        name: companyName,
        name_mm: companyNameMm || undefined,
        business_type: businessType,
        email,
        phone,
        address: address || undefined,
        city: city || undefined,
      });
      // If email failed, show fallback code
      if (res.data?.verification_code) setDevCode(res.data.verification_code);
      setStep(2);
      if (res.data?.email_sent) setDevCode('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  const handleStep2 = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await verifyCompany(email, verificationCode);
      setStep(3);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Verification failed');
    } finally {
      setLoading(false);
    }
  };

  const handleStep3 = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (password !== confirmPassword) { setError('Passwords do not match'); return; }
    if (password.length < 8) { setError('Password must be at least 8 characters'); return; }
    setLoading(true);
    try {
      await setPassword({ email, password, owner_name: ownerName, owner_phone: ownerPhone || phone });
      router.push('/login');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to set password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 via-white to-cyan-50 py-10">
      <div className="w-full max-w-lg mx-4">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary text-white text-2xl font-bold mb-4">HR</div>
          <h1 className="text-3xl font-bold text-gray-900">Easy HR</h1>
          <p className="text-gray-500 mt-1">Create your company account</p>
        </div>

        {/* Steps indicator */}
        <div className="flex items-center justify-center gap-2 mb-6">
          {[1, 2, 3].map((s) => (
            <div key={s} className="flex items-center gap-2">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold ${
                step >= s ? 'bg-primary text-white' : 'bg-gray-200 text-gray-500'
              }`}>{s}</div>
              {s < 3 && <div className={`w-12 h-0.5 ${step > s ? 'bg-primary' : 'bg-gray-200'}`} />}
            </div>
          ))}
        </div>
        <div className="text-center text-sm text-gray-500 mb-6">
          {step === 1 && 'Company Information'}
          {step === 2 && 'Verify Email'}
          {step === 3 && 'Set Owner Password'}
        </div>

        <div className="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
          {error && <div className="mb-4 p-3 rounded-lg bg-red-50 text-red-600 text-sm">{error}</div>}

          {/* Step 1: Company Info */}
          {step === 1 && (
            <form onSubmit={handleStep1} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Company Name *</label>
                <input type="text" value={companyName} onChange={(e) => setCompanyName(e.target.value)} required
                  placeholder="e.g. ABC Company" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Company Name (Myanmar)</label>
                <input type="text" value={companyNameMm} onChange={(e) => setCompanyNameMm(e.target.value)}
                  placeholder="e.g. ABC ကုမ္ပဏီ" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Business Type *</label>
                <select value={businessType} onChange={(e) => setBusinessType(e.target.value)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition">
                  {businessTypes.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required
                  placeholder="admin@company.com" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Phone *</label>
                <input type="text" value={phone} onChange={(e) => setPhone(e.target.value)} required
                  placeholder="09xxxxxxxxx" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
                  <input type="text" value={address} onChange={(e) => setAddress(e.target.value)}
                    placeholder="Street address" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
                  <input type="text" value={city} onChange={(e) => setCity(e.target.value)}
                    placeholder="Yangon" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
                </div>
              </div>
              <button type="submit" disabled={loading}
                className="w-full py-3 bg-primary hover:bg-primary-700 text-white font-semibold rounded-xl transition disabled:opacity-50">
                {loading ? 'Registering...' : 'Register Company'}
              </button>
            </form>
          )}

          {/* Step 2: Verify */}
          {step === 2 && (
            <form onSubmit={handleStep2} className="space-y-4">
              <div className="text-center mb-2">
                <p className="text-gray-600">We sent a verification code to</p>
                <p className="font-semibold text-gray-900">{email}</p>
              </div>
              {devCode && (
                <div className="p-3 rounded-lg bg-amber-50 text-amber-700 text-sm text-center">
                  <p className="font-medium">Development Mode</p>
                  <p>Verification Code: <strong className="text-lg">{devCode}</strong></p>
                </div>
              )}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Verification Code *</label>
                <input type="text" value={verificationCode} onChange={(e) => setVerificationCode(e.target.value)} required
                  placeholder="Enter 6-digit code" maxLength={6}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition text-center text-2xl tracking-widest font-bold" />
              </div>
              <button type="submit" disabled={loading}
                className="w-full py-3 bg-primary hover:bg-primary-700 text-white font-semibold rounded-xl transition disabled:opacity-50">
                {loading ? 'Verifying...' : 'Verify'}
              </button>
              <button type="button" onClick={() => setStep(1)} className="w-full py-2 text-gray-500 hover:text-gray-700 text-sm">
                &larr; Back to registration
              </button>
            </form>
          )}

          {/* Step 3: Set Password */}
          {step === 3 && (
            <form onSubmit={handleStep3} className="space-y-4">
              <div className="text-center mb-2">
                <p className="text-green-600 font-medium">Email verified!</p>
                <p className="text-gray-500 text-sm">Set up your owner account to get started</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Owner Name *</label>
                <input type="text" value={ownerName} onChange={(e) => setOwnerName(e.target.value)} required
                  placeholder="Your full name" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Owner Phone</label>
                <input type="text" value={ownerPhone} onChange={(e) => setOwnerPhone(e.target.value)}
                  placeholder={phone || '09xxxxxxxxx'} className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password *</label>
                <input type="password" value={password} onChange={(e) => setPasswordVal(e.target.value)} required
                  placeholder="Min 8 characters" minLength={8}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Confirm Password *</label>
                <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} required
                  placeholder="Re-enter password"
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition" />
              </div>
              <button type="submit" disabled={loading}
                className="w-full py-3 bg-primary hover:bg-primary-700 text-white font-semibold rounded-xl transition disabled:opacity-50">
                {loading ? 'Setting up...' : 'Complete Setup'}
              </button>
            </form>
          )}

          {step === 1 && (
            <p className="text-center text-sm text-gray-500 mt-4">
              Already have an account?{' '}
              <a href="/login" className="text-primary font-semibold hover:underline">Sign In</a>
            </p>
          )}
        </div>

        <p className="text-center text-gray-400 text-sm mt-6">
          Easy HR &copy; 2026 - Myanmar SME HR Platform
        </p>
      </div>
    </div>
  );
}
