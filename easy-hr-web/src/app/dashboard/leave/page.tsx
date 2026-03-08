'use client';
import { useEffect, useState } from 'react';
import { getPendingLeaves, approveLeave, rejectLeave } from '@/lib/api';
import { CalendarDays, Check, X, Clock } from 'lucide-react';

export default function LeavePage() {
  const [leaves, setLeaves] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadLeaves(); }, []);

  const loadLeaves = async () => {
    setLoading(true);
    try {
      const res = await getPendingLeaves();
      setLeaves(res.data || []);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const handleApprove = async (id: string) => {
    try { await approveLeave(id); loadLeaves(); } catch { alert('Failed'); }
  };

  const handleReject = async (id: string) => {
    const reason = prompt('Rejection reason:');
    if (!reason) return;
    try { await rejectLeave(id, reason); loadLeaves(); } catch { alert('Failed'); }
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Leave Management</h1>
        <p className="text-gray-500 text-sm mt-1">Review and manage leave requests</p>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : leaves.length === 0 ? (
          <div className="text-center py-20 text-gray-400">
            <CalendarDays className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No pending leave requests</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-50">
            {leaves.map((leave: any) => (
              <div key={leave.id} className="p-5 hover:bg-gray-50 transition flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-amber-50 flex items-center justify-center">
                    <Clock className="w-5 h-5 text-amber-500" />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900">
                      {leave.employee?.first_name} {leave.employee?.last_name || ''}
                    </p>
                    <p className="text-sm text-gray-500">
                      {leave.leave_type?.name} &middot; {leave.start_date} → {leave.end_date} &middot; {leave.days} day(s)
                    </p>
                    {leave.reason && <p className="text-xs text-gray-400 mt-1">{leave.reason}</p>}
                  </div>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => handleApprove(leave.id)} className="flex items-center gap-1 px-4 py-2 bg-green-50 text-green-600 rounded-lg hover:bg-green-100 text-sm font-medium transition">
                    <Check size={16} /> Approve
                  </button>
                  <button onClick={() => handleReject(leave.id)} className="flex items-center gap-1 px-4 py-2 bg-red-50 text-red-500 rounded-lg hover:bg-red-100 text-sm font-medium transition">
                    <X size={16} /> Reject
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
