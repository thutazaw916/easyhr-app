'use client';
import { useEffect, useState } from 'react';
import { getPendingPayments, getAllPayments, approvePayment, rejectPayment } from '@/lib/api';

interface Payment {
  id: string;
  company_name?: string;
  company_id?: string;
  amount?: number;
  plan?: string;
  status?: string;
  payment_method?: string;
  screenshot_url?: string;
  email?: string;
  created_at?: string;
  [key: string]: unknown;
}

export default function PaymentsPage() {
  const [tab, setTab] = useState<'pending' | 'all'>('pending');
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const res = tab === 'pending' ? await getPendingPayments() : await getAllPayments();
      setPayments(res.payments || res.data || res || []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [tab]);

  const handleApprove = async (id: string) => {
    if (!confirm('Approve this payment and activate plan?')) return;
    try {
      await approvePayment(id);
      load();
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed');
    }
  };

  const handleReject = async (id: string) => {
    const reason = prompt('Rejection reason:');
    if (!reason) return;
    try {
      await rejectPayment(id, reason);
      load();
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed');
    }
  };

  const statusColor = (s?: string) => {
    if (s === 'approved') return 'bg-green-100 text-green-700';
    if (s === 'rejected') return 'bg-red-100 text-red-700';
    if (s === 'pending') return 'bg-yellow-100 text-yellow-700';
    return 'bg-gray-100 text-gray-700';
  };

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Payment Management</h1>

      <div className="flex gap-2 mb-6">
        <button
          onClick={() => setTab('pending')}
          className={`px-5 py-2 rounded-xl text-sm font-medium transition ${
            tab === 'pending' ? 'bg-primary text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
          }`}
        >
          Pending Approvals
        </button>
        <button
          onClick={() => setTab('all')}
          className={`px-5 py-2 rounded-xl text-sm font-medium transition ${
            tab === 'all' ? 'bg-primary text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
          }`}
        >
          All Payments
        </button>
      </div>

      {error && <p className="text-danger bg-red-50 p-3 rounded-xl mb-4">{error}</p>}

      {loading ? (
        <p className="text-gray-400">Loading...</p>
      ) : payments.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center shadow-sm border border-gray-100">
          <p className="text-4xl mb-3">✅</p>
          <p className="text-gray-500">No {tab === 'pending' ? 'pending' : ''} payments</p>
        </div>
      ) : (
        <div className="space-y-4">
          {payments.map((p) => (
            <div key={p.id} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-semibold text-lg">{p.company_name || 'Unknown Company'}</h3>
                  <p className="text-sm text-gray-500 mt-1">{p.email || p.company_id}</p>
                  <div className="flex gap-3 mt-3">
                    <span className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-lg">
                      Plan: {p.plan || '-'}
                    </span>
                    <span className="text-xs bg-gray-50 text-gray-700 px-2 py-1 rounded-lg">
                      {p.payment_method || 'Unknown method'}
                    </span>
                    <span className={`text-xs px-2 py-1 rounded-lg ${statusColor(p.status)}`}>
                      {p.status || 'pending'}
                    </span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold">{(p.amount || 0).toLocaleString()}</p>
                  <p className="text-xs text-gray-400">MMK</p>
                  <p className="text-xs text-gray-400 mt-1">
                    {p.created_at ? new Date(p.created_at).toLocaleDateString() : ''}
                  </p>
                </div>
              </div>

              {p.screenshot_url && (
                <div className="mt-4 border-t border-gray-100 pt-4">
                  <p className="text-xs text-gray-500 mb-2">Payment Screenshot:</p>
                  <img src={p.screenshot_url} alt="Payment" className="max-w-sm rounded-xl border" />
                </div>
              )}

              {p.status === 'pending' && (
                <div className="mt-4 border-t border-gray-100 pt-4 flex gap-3">
                  <button
                    onClick={() => handleApprove(p.id)}
                    className="px-5 py-2 bg-green-500 text-white rounded-xl text-sm font-medium hover:bg-green-600 transition"
                  >
                    ✅ Approve & Activate
                  </button>
                  <button
                    onClick={() => handleReject(p.id)}
                    className="px-5 py-2 bg-red-50 text-red-600 rounded-xl text-sm font-medium hover:bg-red-100 transition"
                  >
                    Reject
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
