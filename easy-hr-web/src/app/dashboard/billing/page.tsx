'use client';
import { useEffect, useState } from 'react';
import { getSubscription, getPlans, getPaymentHistory } from '@/lib/api';
import { CreditCard, Check, Clock, XCircle } from 'lucide-react';

export default function BillingPage() {
  const [sub, setSub] = useState<any>(null);
  const [plans, setPlans] = useState<any>(null);
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { load(); }, []);

  const load = async () => {
    setLoading(true);
    try {
      const [s, p, h] = await Promise.all([getSubscription(), getPlans(), getPaymentHistory()]);
      setSub(s.data);
      setPlans(p.data);
      setHistory(h.data || []);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const formatMMK = (n: number) => n?.toLocaleString() || '0';

  if (loading) return <div className="flex justify-center py-20"><div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Billing & Subscription</h1>

      {/* Current Plan */}
      <div className="bg-gradient-to-r from-indigo-600 to-cyan-500 rounded-2xl p-6 text-white mb-8">
        <div className="flex items-center justify-between mb-4">
          <div>
            <p className="text-white/70 text-sm">Current Plan</p>
            <p className="text-3xl font-bold">{sub?.current_plan?.label || 'Free'}</p>
          </div>
          <div className="text-right">
            <p className="text-white/70 text-sm">Monthly</p>
            <p className="text-2xl font-bold">{formatMMK(sub?.current_plan?.price || 0)} MMK</p>
          </div>
        </div>
        <div className="flex gap-8 text-sm">
          <div><span className="text-white/60">Employees:</span> <strong>{sub?.employee_count || 0} / {sub?.max_employees || 0}</strong></div>
          <div><span className="text-white/60">Days left:</span> <strong>{sub?.days_remaining || 0}</strong></div>
          <div><span className="text-white/60">Status:</span> <strong className="capitalize">{sub?.subscription_status || 'active'}</strong></div>
        </div>
      </div>

      {/* Plans */}
      <h2 className="text-lg font-bold mb-4">Available Plans</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {(plans?.plans || []).map((plan: any) => {
          const isCurrent = plan.name === sub?.current_plan?.name;
          return (
            <div key={plan.name} className={`bg-white rounded-2xl p-5 border-2 ${isCurrent ? 'border-primary shadow-lg' : 'border-gray-100'}`}>
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-bold text-lg">{plan.label}</h3>
                {isCurrent && <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-primary text-white">CURRENT</span>}
              </div>
              <p className="text-2xl font-bold mb-1">{plan.price === 0 ? 'FREE' : `${formatMMK(plan.price)} MMK`}</p>
              <p className="text-xs text-gray-400 mb-4">{plan.price > 0 ? 'per month' : 'forever'}</p>
              <ul className="space-y-2">
                {(plan.features || []).map((f: string, i: number) => (
                  <li key={i} className="flex items-center gap-2 text-sm text-gray-600">
                    <Check size={14} className="text-green-500 flex-shrink-0" /> {f}
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </div>

      {/* Payment History */}
      <h2 className="text-lg font-bold mb-4">Payment History</h2>
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        {history.length === 0 ? (
          <div className="text-center py-12 text-gray-400"><CreditCard className="w-10 h-10 mx-auto mb-2 opacity-30" /><p>No payments yet</p></div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Date</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Plan</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Method</th>
                <th className="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Amount</th>
                <th className="text-center px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {history.map((p: any) => (
                <tr key={p.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm">{new Date(p.created_at).toLocaleDateString()}</td>
                  <td className="px-6 py-4 font-medium capitalize">{p.plan}</td>
                  <td className="px-6 py-4 text-sm">{p.payment_method}</td>
                  <td className="px-6 py-4 text-right font-semibold">{formatMMK(p.amount)} MMK</td>
                  <td className="px-6 py-4 text-center">
                    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${
                      p.status === 'approved' ? 'bg-green-50 text-green-600' :
                      p.status === 'rejected' ? 'bg-red-50 text-red-500' :
                      'bg-amber-50 text-amber-600'
                    }`}>
                      {p.status === 'approved' ? <Check size={12} /> : p.status === 'rejected' ? <XCircle size={12} /> : <Clock size={12} />}
                      {p.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
