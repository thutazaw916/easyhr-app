'use client';
import { useEffect, useState } from 'react';
import { getDashboard, getRevenue } from '@/lib/api';

interface DashboardData {
  total_companies?: number;
  total_employees?: number;
  active_companies?: number;
  [key: string]: unknown;
}

interface RevenueData {
  total_mrr?: number;
  [key: string]: unknown;
}

export default function DashboardPage() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [revenue, setRevenue] = useState<RevenueData | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    getDashboard().then(setData).catch((e) => setError(e.message));
    getRevenue().then(setRevenue).catch(() => {});
  }, []);

  if (error) return <div className="text-danger bg-red-50 p-4 rounded-xl">{error}</div>;
  if (!data) return <div className="text-gray-400">Loading...</div>;

  const stats = [
    { label: 'Total Companies', value: data.total_companies ?? 0, color: 'bg-blue-500' },
    { label: 'Total Employees', value: data.total_employees ?? 0, color: 'bg-green-500' },
    { label: 'Active Companies', value: data.active_companies ?? 0, color: 'bg-purple-500' },
    { label: 'Monthly Revenue', value: `${(revenue?.total_mrr ?? 0).toLocaleString()} MMK`, color: 'bg-amber-500' },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Platform Overview</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {stats.map((s) => (
          <div key={s.label} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className={`w-10 h-10 ${s.color} rounded-xl flex items-center justify-center text-white text-lg mb-3`}>
              {s.label[0]}
            </div>
            <p className="text-2xl font-bold">{s.value}</p>
            <p className="text-sm text-gray-500 mt-1">{s.label}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
        <h2 className="text-lg font-semibold mb-4">Raw Data (Debug)</h2>
        <pre className="text-xs bg-gray-50 p-4 rounded-xl overflow-auto max-h-96">
          {JSON.stringify({ dashboard: data, revenue }, null, 2)}
        </pre>
      </div>
    </div>
  );
}
