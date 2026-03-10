'use client';
import { useEffect, useState } from 'react';
import { getPendingLeaves, approveLeave, rejectLeave } from '@/lib/api';
import { CalendarDays, Check, X, Clock } from 'lucide-react';
import { useToast } from '@/components/ui/toast';
import { useConfirm } from '@/components/ui/confirm-dialog';

export default function LeavePage() {
  const [leaves, setLeaves] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();
  const { confirm, prompt } = useConfirm();

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
    const ok = await confirm({ title: 'Approve Leave', message: 'Approve this leave request?', confirmText: 'Approve', variant: 'info' });
    if (!ok) return;
    try { await approveLeave(id); toast('Leave approved', 'success'); loadLeaves(); } catch { toast('Failed to approve', 'error'); }
  };

  const handleReject = async (id: string) => {
    const reason = await prompt('Reject Leave', 'Please provide a reason for rejection:', 'Enter reason...');
    if (!reason) return;
    try { await rejectLeave(id, reason); toast('Leave rejected', 'success'); loadLeaves(); } catch { toast('Failed to reject', 'error'); }
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-white">Leave Management</h1>
        <p className="text-[#8E8E93] text-sm mt-1">Review and manage leave requests</p>
      </div>

      <div className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : leaves.length === 0 ? (
          <div className="text-center py-20 text-[#8E8E93]">
            <CalendarDays className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No pending leave requests</p>
          </div>
        ) : (
          <div className="divide-y divide-[#2C2C2E]">
            {leaves.map((leave: any) => (
              <div key={leave.id} className="p-5 hover:bg-[#2C2C2E]/50 transition flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-amber-500/15 flex items-center justify-center">
                    <Clock className="w-5 h-5 text-amber-400" />
                  </div>
                  <div>
                    <p className="font-semibold text-white">
                      {leave.employee?.first_name} {leave.employee?.last_name || ''}
                    </p>
                    <p className="text-sm text-[#8E8E93]">
                      {leave.leave_type?.name} &middot; {leave.start_date} → {leave.end_date} &middot; {leave.days} day(s)
                    </p>
                    {leave.reason && <p className="text-xs text-[#8E8E93] mt-1">{leave.reason}</p>}
                  </div>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => handleApprove(leave.id)} className="flex items-center gap-1 px-4 py-2 bg-emerald-500/15 text-emerald-400 rounded-lg hover:bg-emerald-500/25 text-sm font-medium transition">
                    <Check size={16} /> Approve
                  </button>
                  <button onClick={() => handleReject(leave.id)} className="flex items-center gap-1 px-4 py-2 bg-red-500/15 text-red-400 rounded-lg hover:bg-red-500/25 text-sm font-medium transition">
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
