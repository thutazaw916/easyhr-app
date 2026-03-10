'use client';
import { useEffect, useState } from 'react';
import { getEmployees, addEmployee, deleteEmployee } from '@/lib/api';
import { Users, Plus, Search, Trash2, Phone, Briefcase, Calendar, CreditCard, Hash, User, Shield, ChevronDown, X, Eye } from 'lucide-react';
import { useToast } from '@/components/ui/toast';
import { useConfirm } from '@/components/ui/confirm-dialog';

const COMMON_POSITIONS = [
  'Admin', 'Sales', 'Marketing', 'Accountant', 'Cashier',
  'Driver', 'Security', 'Cleaner', 'Receptionist', 'Manager',
  'Supervisor', 'Technician', 'Engineer', 'Designer', 'Developer',
  'Waiter', 'Chef', 'Delivery', 'Warehouse', 'Quality Control',
];

const ROLE_COLORS: Record<string, string> = {
  owner: 'bg-purple-500/15 text-purple-400',
  hr_manager: 'bg-blue-500/15 text-blue-400',
  department_head: 'bg-amber-500/15 text-amber-400',
  employee: 'bg-[#2C2C2E] text-[#8E8E93]',
};

export default function EmployeesPage() {
  const [employees, setEmployees] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [showDetail, setShowDetail] = useState<any>(null);
  const [pagination, setPagination] = useState<any>({});
  const [page, setPage] = useState(1);
  const [submitting, setSubmitting] = useState(false);
  const [posSearch, setPosSearch] = useState('');
  const [showPosSuggestions, setShowPosSuggestions] = useState(false);
  const { toast } = useToast();
  const { confirm } = useConfirm();

  useEffect(() => { loadEmployees(); }, [page, search]);

  const loadEmployees = async () => {
    setLoading(true);
    try {
      const params: Record<string, string> = { page: String(page), limit: '15' };
      if (search) params.search = search;
      const res = await getEmployees(params);
      setEmployees(res.data.employees || []);
      setPagination(res.data.pagination || {});
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const handleDelete = async (id: string, name: string) => {
    const ok = await confirm({ title: 'Deactivate Employee', message: `Are you sure you want to deactivate ${name}?`, confirmText: 'Deactivate', variant: 'danger' });
    if (!ok) return;
    try {
      await deleteEmployee(id);
      toast('Employee deactivated successfully', 'success');
      loadEmployees();
    } catch (e) { toast('Failed to deactivate employee', 'error'); }
  };

  const handleAdd = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSubmitting(true);
    const form = new FormData(e.currentTarget);
    const phone = (form.get('phone') as string || '').trim();

    if (!/^(09\d{7,9}|\+?959\d{7,9}|0[1-9]\d{6,8})$/.test(phone.replace(/[\s-]/g, ''))) {
      toast('Please enter a valid Myanmar phone number (e.g. 09xxxxxxxxx)', 'error');
      setSubmitting(false);
      return;
    }

    const data: Record<string, any> = {
      first_name: (form.get('first_name') as string || '').trim(),
      phone,
      role: form.get('role'),
      gender: form.get('gender'),
    };
    const position = posSearch.trim();
    const empCode = (form.get('employee_code') as string || '').trim();
    const nrc = (form.get('nrc_number') as string || '').trim();
    const joinDate = (form.get('join_date') as string || '').trim();
    const salary = (form.get('base_salary') as string || '').trim();

    if (position) data.position = position;
    if (empCode) data.employee_code = empCode;
    if (nrc) data.nrc_number = nrc;
    if (joinDate) data.join_date = joinDate;
    if (salary) data.base_salary = salary;

    try {
      await addEmployee(data);
      setShowAdd(false);
      setPosSearch('');
      toast('Employee added successfully!', 'success');
      loadEmployees();
    } catch (err: any) {
      toast(err.response?.data?.message || 'Failed to add employee', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const filteredPositions = posSearch
    ? COMMON_POSITIONS.filter(p => p.toLowerCase().includes(posSearch.toLowerCase()))
    : COMMON_POSITIONS;

  const inputClass = "w-full px-4 py-2.5 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition text-sm placeholder-[#8E8E93]";
  const labelClass = "text-xs font-semibold text-[#8E8E93] uppercase tracking-wide mb-1.5 block";

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Employees</h1>
          <p className="text-[#8E8E93] text-sm mt-1">{pagination.total || 0} total employees</p>
        </div>
        <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 px-5 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition font-medium shadow-sm shadow-primary/20">
          <Plus size={18} /> Add Employee
        </button>
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-[#8E8E93]" size={18} />
        <input
          type="text"
          placeholder="Search by name, phone, position..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          className="w-full pl-11 pr-4 py-3 rounded-xl border border-[#38383A] bg-[#1C1C1E] text-white placeholder-[#8E8E93] focus:ring-2 focus:ring-primary/30 focus:border-primary outline-none transition"
        />
      </div>

      {/* Table */}
      <div className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : employees.length === 0 ? (
          <div className="text-center py-20 text-[#8E8E93]">
            <Users className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p className="font-medium">No employees found</p>
            <p className="text-sm mt-1">Add your first employee to get started</p>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-[#2C2C2E]">
              <tr>
                <th className="text-left px-6 py-3.5 text-xs font-semibold text-[#8E8E93] uppercase tracking-wide">Employee</th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold text-[#8E8E93] uppercase tracking-wide">Phone</th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold text-[#8E8E93] uppercase tracking-wide hidden md:table-cell">Position</th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold text-[#8E8E93] uppercase tracking-wide hidden lg:table-cell">Join Date</th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold text-[#8E8E93] uppercase tracking-wide">Role</th>
                <th className="text-left px-6 py-3.5 text-xs font-semibold text-[#8E8E93] uppercase tracking-wide">Status</th>
                <th className="text-right px-6 py-3.5 text-xs font-semibold text-[#8E8E93] uppercase tracking-wide">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2C2C2E]">
              {employees.map((emp) => (
                <tr key={emp.id} className="hover:bg-[#2C2C2E]/50 transition group">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary-400 font-bold text-sm shrink-0">
                        {(emp.first_name || '?')[0].toUpperCase()}
                      </div>
                      <div className="min-w-0">
                        <p className="font-semibold text-white truncate">{emp.first_name} {emp.last_name || ''}</p>
                        {emp.employee_code && <p className="text-xs text-[#8E8E93]">#{emp.employee_code}</p>}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1.5 text-sm text-[#8E8E93]"><Phone size={14} className="text-[#8E8E93]" /> {emp.phone}</div>
                  </td>
                  <td className="px-6 py-4 hidden md:table-cell">
                    <span className="text-sm text-[#8E8E93]">{emp.position || emp.department?.name || '-'}</span>
                  </td>
                  <td className="px-6 py-4 hidden lg:table-cell">
                    <span className="text-sm text-[#8E8E93]">{emp.join_date ? new Date(emp.join_date).toLocaleDateString() : '-'}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium capitalize ${ROLE_COLORS[emp.role] || 'bg-gray-100 text-gray-600'}`}>
                      {emp.role?.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${emp.is_active ? 'bg-emerald-500/15 text-emerald-400' : 'bg-red-500/15 text-red-400'}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${emp.is_active ? 'bg-green-500' : 'bg-red-400'}`} />
                      {emp.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition">
                      <button onClick={() => setShowDetail(emp)} className="p-2 hover:bg-blue-500/10 rounded-lg text-[#8E8E93] hover:text-blue-400 transition" title="View Details">
                        <Eye size={16} />
                      </button>
                      <button onClick={() => handleDelete(emp.id, emp.first_name)} className="p-2 hover:bg-red-500/10 rounded-lg text-[#8E8E93] hover:text-red-400 transition" title="Deactivate">
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Pagination */}
      {pagination.total_pages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-[#8E8E93]">Page {page} of {pagination.total_pages}</p>
          <div className="flex gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} className="px-4 py-2 rounded-lg border border-[#38383A] text-sm text-[#8E8E93] disabled:opacity-30 hover:bg-[#1C1C1E]">Previous</button>
            <button onClick={() => setPage(p => p + 1)} disabled={page >= pagination.total_pages} className="px-4 py-2 rounded-lg border border-[#38383A] text-sm text-[#8E8E93] disabled:opacity-30 hover:bg-[#1C1C1E]">Next</button>
          </div>
        </div>
      )}

      {/* Add Employee Modal */}
      {showAdd && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => setShowAdd(false)}>
          <div className="bg-[#1C1C1E] rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto border border-[#38383A]" onClick={(e) => e.stopPropagation()}>
            <div className="sticky top-0 bg-[#1C1C1E] border-b border-[#38383A] px-6 py-4 rounded-t-2xl flex items-center justify-between">
              <h3 className="text-lg font-bold text-white">Add New Employee</h3>
              <button onClick={() => setShowAdd(false)} className="p-1.5 hover:bg-[#2C2C2E] rounded-lg transition text-[#8E8E93]"><X size={18} /></button>
            </div>
            <form onSubmit={handleAdd} className="p-6 space-y-5">
              {/* Personal Info */}
              <div>
                <h4 className="text-sm font-bold text-[#8E8E93] mb-3 flex items-center gap-2"><User size={15} className="text-primary" /> Personal Information</h4>
                <div className="space-y-3">
                  <div>
                    <label className={labelClass}>Full Name *</label>
                    <input name="first_name" placeholder="e.g. Mg Mg" required className={inputClass} />
                  </div>
                  <div>
                    <label className={labelClass}>Phone Number *</label>
                    <input name="phone" placeholder="09xxxxxxxxx" required className={inputClass} />
                    <p className="text-xs text-blue-400 mt-1 italic">* Employee will use this phone for OTP login</p>
                    <p className="text-xs text-[#8E8E93] mt-0.5">Formats: 09xxx, +959xxx, 01xxx (Yangon)</p>
                  </div>
                  <div>
                    <label className={labelClass}>NRC Number</label>
                    <input name="nrc_number" placeholder="12/xxx(N)xxxxxx" className={inputClass} />
                  </div>
                  <div>
                    <label className={labelClass}>Gender</label>
                    <select name="gender" className={inputClass}>
                      <option value="male">Male</option>
                      <option value="female">Female</option>
                    </select>
                  </div>
                  <div>
                    <label className={labelClass}>Employee Code</label>
                    <input name="employee_code" placeholder="Auto-generated if empty" className={inputClass} />
                  </div>
                </div>
              </div>

              {/* Work Info */}
              <div>
                <h4 className="text-sm font-bold text-[#8E8E93] mb-3 flex items-center gap-2"><Briefcase size={15} className="text-primary" /> Work Information</h4>
                <div className="space-y-3">
                  <div>
                    <label className={labelClass}>System Role</label>
                    <select name="role" className={inputClass}>
                      <option value="employee">Employee</option>
                      <option value="hr_manager">HR Manager</option>
                      <option value="department_head">Department Head</option>
                    </select>
                  </div>
                  <div className="relative">
                    <label className={labelClass}>Position / Job Title</label>
                    <input
                      value={posSearch}
                      onChange={(e) => { setPosSearch(e.target.value); setShowPosSuggestions(true); }}
                      onFocus={() => setShowPosSuggestions(true)}
                      placeholder="Type position (e.g. Sales, Admin, Driver...)"
                      className={inputClass}
                    />
                    {showPosSuggestions && filteredPositions.length > 0 && (
                      <div className="absolute z-10 w-full mt-1 bg-[#2C2C2E] border border-[#38383A] rounded-xl shadow-lg max-h-40 overflow-y-auto">
                        {filteredPositions.map((pos) => (
                          <button key={pos} type="button" onClick={() => { setPosSearch(pos); setShowPosSuggestions(false); }}
                            className="w-full text-left px-4 py-2 text-sm text-white hover:bg-primary/10 hover:text-primary transition flex items-center gap-2">
                            <Briefcase size={14} className="text-[#8E8E93]" /> {pos}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                  <div>
                    <label className={labelClass}>Join Date</label>
                    <input name="join_date" type="date" className={inputClass} />
                  </div>
                  <div>
                    <label className={labelClass}>Base Salary (MMK)</label>
                    <input name="base_salary" type="number" placeholder="Optional" className={inputClass} />
                  </div>
                </div>
              </div>

              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowAdd(false)} className="flex-1 py-2.5 rounded-xl border border-[#38383A] text-[#8E8E93] hover:bg-[#2C2C2E] font-medium transition">Cancel</button>
                <button type="submit" disabled={submitting} className="flex-1 py-2.5 rounded-xl bg-primary text-white hover:bg-primary-700 font-medium transition disabled:opacity-50 flex items-center justify-center gap-2">
                  {submitting ? <><div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Adding...</> : <><Plus size={16} /> Add Employee</>}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Employee Detail Modal */}
      {showDetail && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => setShowDetail(null)}>
          <div className="bg-[#1C1C1E] rounded-2xl w-full max-w-md max-h-[85vh] overflow-y-auto border border-[#38383A]" onClick={(e) => e.stopPropagation()}>
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-bold text-white">Employee Details</h3>
                <button onClick={() => setShowDetail(null)} className="p-1.5 hover:bg-[#2C2C2E] rounded-lg transition text-[#8E8E93]"><X size={18} /></button>
              </div>
              <div className="flex flex-col items-center mb-6">
                <div className="w-20 h-20 rounded-full bg-primary/20 flex items-center justify-center text-primary-400 font-bold text-2xl mb-3">
                  {(showDetail.first_name || '?')[0].toUpperCase()}
                </div>
                <h4 className="text-xl font-bold text-white">{showDetail.first_name} {showDetail.last_name || ''}</h4>
                <span className={`mt-2 px-3 py-1 rounded-full text-xs font-medium capitalize ${ROLE_COLORS[showDetail.role] || 'bg-gray-100 text-gray-600'}`}>
                  {showDetail.role?.replace('_', ' ')}
                </span>
              </div>
              <div className="space-y-3">
                {[
                  { label: 'Phone', value: showDetail.phone, icon: Phone },
                  { label: 'Position', value: showDetail.position || '-', icon: Briefcase },
                  { label: 'Employee Code', value: showDetail.employee_code || '-', icon: Hash },
                  { label: 'Gender', value: showDetail.gender || '-', icon: User },
                  { label: 'NRC', value: showDetail.nrc_number || '-', icon: CreditCard },
                  { label: 'Join Date', value: showDetail.join_date ? new Date(showDetail.join_date).toLocaleDateString() : '-', icon: Calendar },
                  { label: 'Base Salary', value: showDetail.base_salary ? `${Number(showDetail.base_salary).toLocaleString()} MMK` : '-', icon: CreditCard },
                  { label: 'Status', value: showDetail.is_active ? 'Active' : 'Inactive', icon: Shield },
                ].map((item, i) => (
                  <div key={i} className="flex items-center justify-between py-2.5 border-b border-[#2C2C2E] last:border-0">
                    <div className="flex items-center gap-2 text-sm text-[#8E8E93]">
                      <item.icon size={15} className="text-[#8E8E93]" /> {item.label}
                    </div>
                    <span className="text-sm font-medium text-white capitalize">{item.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
