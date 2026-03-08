'use client';
import { useEffect, useState } from 'react';
import { getMonthlyPayroll, calculatePayroll } from '@/lib/api';
import { Wallet, Calculator, Download } from 'lucide-react';
import { useToast } from '@/components/ui/toast';
import { useConfirm } from '@/components/ui/confirm-dialog';

export default function PayrollPage() {
  const [payroll, setPayroll] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);
  const { toast } = useToast();
  const { confirm } = useConfirm();

  useEffect(() => { loadPayroll(); }, [year, month]);

  const loadPayroll = async () => {
    setLoading(true);
    try {
      const res = await getMonthlyPayroll(year, month);
      setPayroll(res.data);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const handleCalculate = async () => {
    const ok = await confirm({ title: 'Calculate Payroll', message: `Calculate payroll for ${new Date(2024, month-1).toLocaleString('en', {month:'long'})} ${year}?`, confirmText: 'Calculate', variant: 'info' });
    if (!ok) return;
    try {
      await calculatePayroll(year, month);
      toast('Payroll calculated successfully!', 'success');
      loadPayroll();
    } catch (e) { toast('Failed to calculate payroll', 'error'); }
  };

  const records = payroll?.payroll || payroll?.records || [];
  const formatMMK = (n: number) => n?.toLocaleString() || '0';

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Payroll</h1>
          <p className="text-gray-500 text-sm mt-1">Monthly salary management</p>
        </div>
        <div className="flex items-center gap-3">
          <select value={month} onChange={(e) => setMonth(Number(e.target.value))} className="px-3 py-2.5 rounded-xl border border-gray-200 outline-none">
            {[1,2,3,4,5,6,7,8,9,10,11,12].map(m => <option key={m} value={m}>{new Date(2024, m-1).toLocaleString('en', {month:'long'})}</option>)}
          </select>
          <select value={year} onChange={(e) => setYear(Number(e.target.value))} className="px-3 py-2.5 rounded-xl border border-gray-200 outline-none">
            {[2024,2025,2026].map(y => <option key={y} value={y}>{y}</option>)}
          </select>
          <button onClick={handleCalculate} className="flex items-center gap-2 px-4 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition font-medium">
            <Calculator size={18} /> Calculate
          </button>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-20"><div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" /></div>
        ) : records.length === 0 ? (
          <div className="text-center py-20 text-gray-400">
            <Wallet className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No payroll records for this month</p>
            <button onClick={handleCalculate} className="mt-3 px-4 py-2 bg-primary text-white rounded-lg text-sm">Calculate Now</button>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Employee</th>
                <th className="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Basic Salary</th>
                <th className="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Allowances</th>
                <th className="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Deductions</th>
                <th className="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Net Salary</th>
                <th className="text-center px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {records.map((r: any) => (
                <tr key={r.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 font-medium">{r.employee?.first_name || r.first_name} {r.employee?.last_name || r.last_name || ''}</td>
                  <td className="px-6 py-4 text-right text-sm">{formatMMK(r.basic_salary)} MMK</td>
                  <td className="px-6 py-4 text-right text-sm text-green-600">+{formatMMK(r.total_allowances || 0)}</td>
                  <td className="px-6 py-4 text-right text-sm text-red-500">-{formatMMK(r.total_deductions || 0)}</td>
                  <td className="px-6 py-4 text-right font-bold">{formatMMK(r.net_salary)} MMK</td>
                  <td className="px-6 py-4 text-center">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${r.status === 'paid' ? 'bg-green-50 text-green-600' : 'bg-amber-50 text-amber-600'}`}>
                      {r.status || 'pending'}
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
