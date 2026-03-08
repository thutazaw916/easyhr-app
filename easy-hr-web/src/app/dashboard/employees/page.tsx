'use client';
import { useEffect, useState } from 'react';
import { getEmployees, addEmployee, deleteEmployee } from '@/lib/api';
import { Users, Plus, Search, Trash2, Edit, Phone, Mail, Building2 } from 'lucide-react';

export default function EmployeesPage() {
  const [employees, setEmployees] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [pagination, setPagination] = useState<any>({});
  const [page, setPage] = useState(1);

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
    if (!confirm(`Deactivate ${name}?`)) return;
    try {
      await deleteEmployee(id);
      loadEmployees();
    } catch (e) { alert('Failed to deactivate'); }
  };

  const handleAdd = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    try {
      await addEmployee({
        first_name: form.get('first_name'),
        last_name: form.get('last_name'),
        phone: form.get('phone'),
        email: form.get('email'),
        role: form.get('role'),
        gender: form.get('gender'),
      });
      setShowAdd(false);
      loadEmployees();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to add');
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Employees</h1>
          <p className="text-gray-500 text-sm mt-1">{pagination.total || 0} total employees</p>
        </div>
        <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 px-4 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition font-medium">
          <Plus size={18} /> Add Employee
        </button>
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
        <input
          type="text"
          placeholder="Search by name, phone, email..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          className="w-full pl-11 pr-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
        />
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : employees.length === 0 ? (
          <div className="text-center py-20 text-gray-400">
            <Users className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No employees found</p>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Employee</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Contact</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Department</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Role</th>
                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Status</th>
                <th className="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {employees.map((emp) => (
                <tr key={emp.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-sm">
                        {(emp.first_name || '?')[0].toUpperCase()}
                      </div>
                      <div>
                        <p className="font-semibold text-gray-900">{emp.first_name} {emp.last_name || ''}</p>
                        <p className="text-xs text-gray-400">{emp.name_mm || ''}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1 text-sm text-gray-600"><Phone size={14} /> {emp.phone}</div>
                    {emp.email && <div className="flex items-center gap-1 text-xs text-gray-400 mt-1"><Mail size={12} /> {emp.email}</div>}
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-gray-600">{emp.department?.name || '-'}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="inline-block px-2.5 py-1 rounded-full text-xs font-medium bg-primary/10 text-primary capitalize">
                      {emp.role?.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium ${emp.is_active ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-500'}`}>
                      {emp.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button onClick={() => handleDelete(emp.id, emp.first_name)} className="p-2 hover:bg-red-50 rounded-lg text-gray-400 hover:text-red-500 transition">
                      <Trash2 size={16} />
                    </button>
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
          <p className="text-sm text-gray-500">Page {page} of {pagination.total_pages}</p>
          <div className="flex gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} className="px-4 py-2 rounded-lg border text-sm disabled:opacity-30 hover:bg-gray-50">Previous</button>
            <button onClick={() => setPage(p => p + 1)} disabled={page >= pagination.total_pages} className="px-4 py-2 rounded-lg border text-sm disabled:opacity-30 hover:bg-gray-50">Next</button>
          </div>
        </div>
      )}

      {/* Add Modal */}
      {showAdd && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold mb-4">Add New Employee</h3>
            <form onSubmit={handleAdd} className="space-y-3">
              <input name="first_name" placeholder="First Name *" required className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
              <input name="last_name" placeholder="Last Name" className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
              <input name="phone" placeholder="Phone * (09...)" required className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
              <input name="email" type="email" placeholder="Email" className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
              <select name="role" className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary">
                <option value="employee">Employee</option>
                <option value="hr_manager">HR Manager</option>
                <option value="department_head">Department Head</option>
              </select>
              <select name="gender" className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary">
                <option value="male">Male</option>
                <option value="female">Female</option>
              </select>
              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowAdd(false)} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50 font-medium">Cancel</button>
                <button type="submit" className="flex-1 py-2.5 rounded-xl bg-primary text-white hover:bg-primary-700 font-medium">Add Employee</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
