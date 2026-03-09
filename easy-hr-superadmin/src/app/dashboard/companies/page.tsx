'use client';
import { useEffect, useState } from 'react';
import { getCompanies, suspendCompany, unsuspendCompany, updatePlan } from '@/lib/api';

interface Company {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  plan?: string;
  status?: string;
  employee_count?: number;
  created_at?: string;
  [key: string]: unknown;
}

export default function CompaniesPage() {
  const [companies, setCompanies] = useState<Company[]>([]);
  const [filter, setFilter] = useState('');
  const [search, setSearch] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const params: Record<string, string> = {};
      if (filter) params.plan = filter;
      if (search) params.search = search;
      const res = await getCompanies(params);
      setCompanies(res.companies || res.data || res || []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [filter]);

  const handleSuspend = async (id: string) => {
    if (!confirm('Suspend this company?')) return;
    try {
      await suspendCompany(id, 'Payment overdue');
      load();
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed');
    }
  };

  const handleUnsuspend = async (id: string) => {
    try {
      await unsuspendCompany(id);
      load();
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed');
    }
  };

  const handlePlanChange = async (id: string, plan: string) => {
    try {
      await updatePlan(id, { plan });
      load();
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed');
    }
  };

  const planBadge = (plan?: string) => {
    const colors: Record<string, string> = {
      free: 'bg-gray-100 text-gray-700',
      starter: 'bg-blue-100 text-blue-700',
      business: 'bg-purple-100 text-purple-700',
      enterprise: 'bg-amber-100 text-amber-700',
    };
    return colors[plan || 'free'] || colors.free;
  };

  const statusBadge = (status?: string) => {
    if (status === 'suspended') return 'bg-red-100 text-red-700';
    if (status === 'active') return 'bg-green-100 text-green-700';
    return 'bg-gray-100 text-gray-700';
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Companies</h1>
        <span className="text-sm text-gray-500">{companies.length} total</span>
      </div>

      {/* Filters */}
      <div className="flex gap-3 mb-6">
        <input
          type="text"
          placeholder="Search company..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && load()}
          className="flex-1 px-4 py-2 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary outline-none"
        />
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="px-4 py-2 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary outline-none"
        >
          <option value="">All Plans</option>
          <option value="free">Free</option>
          <option value="starter">Starter</option>
          <option value="business">Business</option>
          <option value="enterprise">Enterprise</option>
        </select>
        <button onClick={load} className="px-4 py-2 bg-primary text-white rounded-xl hover:bg-primary-700 transition">
          Search
        </button>
      </div>

      {error && <p className="text-danger bg-red-50 p-3 rounded-xl mb-4">{error}</p>}

      {loading ? (
        <p className="text-gray-400">Loading...</p>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100">
                <th className="text-left px-6 py-4 font-medium text-gray-500">Company</th>
                <th className="text-left px-6 py-4 font-medium text-gray-500">Plan</th>
                <th className="text-left px-6 py-4 font-medium text-gray-500">Status</th>
                <th className="text-left px-6 py-4 font-medium text-gray-500">Employees</th>
                <th className="text-left px-6 py-4 font-medium text-gray-500">Joined</th>
                <th className="text-right px-6 py-4 font-medium text-gray-500">Actions</th>
              </tr>
            </thead>
            <tbody>
              {companies.map((c) => (
                <tr key={c.id} className="border-b border-gray-50 hover:bg-gray-50 transition">
                  <td className="px-6 py-4">
                    <p className="font-medium">{c.name}</p>
                    <p className="text-xs text-gray-400">{c.email}</p>
                  </td>
                  <td className="px-6 py-4">
                    <select
                      value={c.plan || 'free'}
                      onChange={(e) => handlePlanChange(c.id, e.target.value)}
                      className={`text-xs font-medium px-2 py-1 rounded-lg ${planBadge(c.plan)} border-0 cursor-pointer`}
                    >
                      <option value="free">Free</option>
                      <option value="starter">Starter</option>
                      <option value="business">Business</option>
                      <option value="enterprise">Enterprise</option>
                    </select>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs font-medium px-2 py-1 rounded-lg ${statusBadge(c.status)}`}>
                      {c.status || 'active'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-600">{c.employee_count ?? '-'}</td>
                  <td className="px-6 py-4 text-gray-400 text-xs">
                    {c.created_at ? new Date(c.created_at).toLocaleDateString() : '-'}
                  </td>
                  <td className="px-6 py-4 text-right">
                    {c.status === 'suspended' ? (
                      <button onClick={() => handleUnsuspend(c.id)} className="text-xs text-green-600 hover:underline">
                        Unsuspend
                      </button>
                    ) : (
                      <button onClick={() => handleSuspend(c.id)} className="text-xs text-red-500 hover:underline">
                        Suspend
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {companies.length === 0 && (
                <tr><td colSpan={6} className="px-6 py-8 text-center text-gray-400">No companies found</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
