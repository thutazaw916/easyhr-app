'use client';
import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: '📊' },
  { href: '/dashboard/companies', label: 'Companies', icon: '🏢' },
  { href: '/dashboard/whitelist', label: 'Email Whitelist', icon: '📧' },
  { href: '/dashboard/payments', label: 'Payments', icon: '💳' },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [admin, setAdmin] = useState<{ name?: string; email?: string } | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('sa_token');
    if (!token) { router.replace('/login'); return; }
    try {
      const user = JSON.parse(localStorage.getItem('sa_user') || '{}');
      setAdmin(user);
    } catch { setAdmin({}); }
  }, [router]);

  const logout = () => {
    localStorage.removeItem('sa_token');
    localStorage.removeItem('sa_user');
    router.replace('/login');
  };

  return (
    <div className="min-h-screen flex bg-black">
      {/* Sidebar */}
      <aside className="w-64 bg-[#1C1C1E] text-white flex flex-col border-r border-[#38383A]">
        <div className="p-6 border-b border-[#38383A]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-lg font-bold">E</div>
            <div>
              <h1 className="font-bold text-lg">Easy HR</h1>
              <p className="text-xs text-[#8E8E93]">Super Admin</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const active = pathname === item.href || (item.href !== '/dashboard' && pathname?.startsWith(item.href));
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition ${
                  active ? 'bg-primary text-white' : 'text-[#8E8E93] hover:bg-[#2C2C2E] hover:text-white'
                }`}
              >
                <span>{item.icon}</span>
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-[#38383A]">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-8 h-8 rounded-full bg-[#2C2C2E] flex items-center justify-center text-sm">
              {admin?.name?.[0] || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{admin?.name || 'Admin'}</p>
              <p className="text-xs text-[#8E8E93] truncate">{admin?.email || ''}</p>
            </div>
          </div>
          <button onClick={logout} className="w-full text-left text-sm text-[#8E8E93] hover:text-white px-2 py-1 transition">
            Sign out →
          </button>
        </div>
      </aside>

      {/* Main */}
      <main className="flex-1 overflow-auto">
        <div className="p-8">{children}</div>
      </main>
    </div>
  );
}
