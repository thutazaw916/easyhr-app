'use client';
import { useEffect, useState } from 'react';
import { getDailyReport } from '@/lib/api';
import { Clock, UserCheck, UserX, AlertTriangle } from 'lucide-react';

export default function AttendancePage() {
  const [report, setReport] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);

  useEffect(() => { loadReport(); }, [date]);

  const loadReport = async () => {
    setLoading(true);
    try {
      const res = await getDailyReport(date);
      setReport(res.data);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const records = report?.records || report?.attendance || [];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Attendance</h1>
          <p className="text-[#8E8E93] text-sm mt-1">Daily attendance report</p>
        </div>
        <input type="date" value={date} onChange={(e) => setDate(e.target.value)}
          className="px-4 py-2.5 rounded-xl border border-[#38383A] bg-[#1C1C1E] text-white outline-none focus:ring-2 focus:ring-primary" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-[#1C1C1E] rounded-xl p-5 border border-[#38383A] flex items-center gap-4">
          <div className="w-12 h-12 bg-emerald-500/15 rounded-xl flex items-center justify-center"><UserCheck className="text-emerald-400" size={24} /></div>
          <div><p className="text-2xl font-bold text-white">{report?.present_count || records.filter((r: any) => r.check_in_time).length}</p><p className="text-sm text-[#8E8E93]">Present</p></div>
        </div>
        <div className="bg-[#1C1C1E] rounded-xl p-5 border border-[#38383A] flex items-center gap-4">
          <div className="w-12 h-12 bg-red-500/15 rounded-xl flex items-center justify-center"><UserX className="text-red-400" size={24} /></div>
          <div><p className="text-2xl font-bold text-white">{report?.absent_count || 0}</p><p className="text-sm text-[#8E8E93]">Absent</p></div>
        </div>
        <div className="bg-[#1C1C1E] rounded-xl p-5 border border-[#38383A] flex items-center gap-4">
          <div className="w-12 h-12 bg-amber-500/15 rounded-xl flex items-center justify-center"><AlertTriangle className="text-amber-400" size={24} /></div>
          <div><p className="text-2xl font-bold text-white">{report?.late_count || 0}</p><p className="text-sm text-[#8E8E93]">Late</p></div>
        </div>
      </div>

      <div className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-20"><div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" /></div>
        ) : records.length === 0 ? (
          <div className="text-center py-20 text-[#8E8E93]"><Clock className="w-12 h-12 mx-auto mb-3 opacity-30" /><p>No attendance records for this date</p></div>
        ) : (
          <table className="w-full">
            <thead className="bg-[#2C2C2E]">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-semibold text-[#8E8E93] uppercase">Employee</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-[#8E8E93] uppercase">Check In</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-[#8E8E93] uppercase">Check Out</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-[#8E8E93] uppercase">Hours</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-[#8E8E93] uppercase">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2C2C2E]">
              {records.map((r: any) => (
                <tr key={r.id} className="hover:bg-[#2C2C2E]/50">
                  <td className="px-6 py-4 font-medium text-white">{r.employee?.first_name || r.first_name || '-'} {r.employee?.last_name || r.last_name || ''}</td>
                  <td className="px-6 py-4 text-sm text-[#8E8E93]">{r.check_in_time ? new Date(r.check_in_time).toLocaleTimeString() : '-'}</td>
                  <td className="px-6 py-4 text-sm text-[#8E8E93]">{r.check_out_time ? new Date(r.check_out_time).toLocaleTimeString() : '-'}</td>
                  <td className="px-6 py-4 text-sm text-[#8E8E93]">{r.total_hours ? `${Number(r.total_hours).toFixed(1)}h` : '-'}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${
                      r.status === 'present' ? 'bg-emerald-500/15 text-emerald-400' :
                      r.status === 'late' ? 'bg-amber-500/15 text-amber-400' :
                      'bg-red-500/15 text-red-400'
                    }`}>{r.status || (r.check_in_time ? 'present' : 'absent')}</span>
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
