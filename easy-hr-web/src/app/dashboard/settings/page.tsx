'use client';
import { useEffect, useState } from 'react';
import { getCompanySettings, updateCompanySettings, getDepartments, getBranches, addDepartment, addBranch } from '@/lib/api';
import { Settings, Save, Building2, Users, Plus, X, MapPin, Clock } from 'lucide-react';

export default function SettingsPage() {
  const [settings, setSettings] = useState<any>(null);
  const [departments, setDepartments] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showAddDept, setShowAddDept] = useState(false);
  const [showAddBranch, setShowAddBranch] = useState(false);
  const [tab, setTab] = useState<'schedule' | 'departments' | 'branches'>('schedule');

  useEffect(() => { load(); }, []);

  const load = async () => {
    setLoading(true);
    try {
      const [s, d, b] = await Promise.allSettled([getCompanySettings(), getDepartments(), getBranches()]);
      if (s.status === 'fulfilled') setSettings(s.value.data);
      if (d.status === 'fulfilled') setDepartments(d.value.data || []);
      if (b.status === 'fulfilled') setBranches(b.value.data || []);
    } catch {}
    setLoading(false);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateCompanySettings(settings);
      alert('Settings saved!');
    } catch { alert('Failed to save'); }
    setSaving(false);
  };

  const handleAddDept = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    try {
      await addDepartment({ name: form.get('name'), name_mm: form.get('name_mm') || undefined });
      setShowAddDept(false);
      load();
    } catch (err: any) { alert(err.response?.data?.message || 'Failed'); }
  };

  const handleAddBranch = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    try {
      await addBranch({
        name: form.get('name'),
        address: form.get('address') || undefined,
        latitude: form.get('latitude') ? Number(form.get('latitude')) : undefined,
        longitude: form.get('longitude') ? Number(form.get('longitude')) : undefined,
      });
      setShowAddBranch(false);
      load();
    } catch (err: any) { alert(err.response?.data?.message || 'Failed'); }
  };

  const inputClass = "w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition text-sm";

  if (loading) return <div className="flex justify-center py-20"><div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" /></div>;

  const tabs = [
    { key: 'schedule', label: 'Work Schedule', icon: Clock },
    { key: 'departments', label: `Departments (${departments.length})`, icon: Users },
    { key: 'branches', label: `Branches (${branches.length})`, icon: Building2 },
  ] as const;

  return (
    <div className="max-w-4xl">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Company Settings</h1>

      {/* Tabs */}
      <div className="flex gap-1 bg-gray-100 p-1 rounded-xl mb-6">
        {tabs.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)}
            className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-lg text-sm font-medium transition ${tab === t.key ? 'bg-white text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}>
            <t.icon size={16} /> {t.label}
          </button>
        ))}
      </div>

      {/* Work Schedule */}
      {tab === 'schedule' && (
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-lg font-semibold mb-4 flex items-center gap-2"><Settings size={20} className="text-primary" /> Work Schedule</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Work Start Time</label>
              <input type="time" value={settings?.work_start_time || '09:00'} onChange={(e) => setSettings({...settings, work_start_time: e.target.value})} className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Work End Time</label>
              <input type="time" value={settings?.work_end_time || '17:00'} onChange={(e) => setSettings({...settings, work_end_time: e.target.value})} className={inputClass} />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Late Threshold (minutes)</label>
              <input type="number" value={settings?.late_threshold_minutes || 15} onChange={(e) => setSettings({...settings, late_threshold_minutes: Number(e.target.value)})} className={inputClass} />
              <p className="text-xs text-gray-400 mt-1">Employees arriving after this many minutes will be marked late</p>
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Check-in Radius (meters)</label>
              <input type="number" value={settings?.checkin_radius_meters || 200} onChange={(e) => setSettings({...settings, checkin_radius_meters: Number(e.target.value)})} className={inputClass} />
              <p className="text-xs text-gray-400 mt-1">GPS radius for valid check-in location</p>
            </div>
          </div>
          <button onClick={handleSave} disabled={saving}
            className="mt-6 flex items-center gap-2 px-5 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition font-medium disabled:opacity-50 shadow-sm shadow-primary/20">
            <Save size={16} /> {saving ? 'Saving...' : 'Save Settings'}
          </button>
        </div>
      )}

      {/* Departments */}
      {tab === 'departments' && (
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold flex items-center gap-2"><Users size={20} className="text-primary" /> Departments</h2>
            <button onClick={() => setShowAddDept(true)} className="flex items-center gap-1.5 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium hover:bg-primary-700 transition">
              <Plus size={16} /> Add Department
            </button>
          </div>
          {departments.length === 0 ? (
            <div className="text-center py-12 text-gray-400">
              <Users className="w-10 h-10 mx-auto mb-2 opacity-30" />
              <p className="text-sm">No departments yet</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {departments.map((d: any) => (
                <div key={d.id} className="p-4 rounded-xl bg-gray-50 border border-gray-100 hover:border-primary/30 transition">
                  <p className="font-semibold text-gray-900">{d.name}</p>
                  {d.name_mm && <p className="text-xs text-gray-400 mt-0.5">{d.name_mm}</p>}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Branches */}
      {tab === 'branches' && (
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold flex items-center gap-2"><Building2 size={20} className="text-primary" /> Branches</h2>
            <button onClick={() => setShowAddBranch(true)} className="flex items-center gap-1.5 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium hover:bg-primary-700 transition">
              <Plus size={16} /> Add Branch
            </button>
          </div>
          {branches.length === 0 ? (
            <div className="text-center py-12 text-gray-400">
              <Building2 className="w-10 h-10 mx-auto mb-2 opacity-30" />
              <p className="text-sm">No branches yet</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {branches.map((b: any) => (
                <div key={b.id} className="p-4 rounded-xl bg-gray-50 border border-gray-100 hover:border-primary/30 transition">
                  <p className="font-semibold text-gray-900">{b.name}</p>
                  {b.address && <p className="text-xs text-gray-500 mt-1 flex items-center gap-1"><MapPin size={12} /> {b.address}</p>}
                  {b.latitude && <p className="text-xs text-gray-400 mt-0.5">GPS: {b.latitude}, {b.longitude}</p>}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Add Department Modal */}
      {showAddDept && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => setShowAddDept(false)}>
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold">Add Department</h3>
              <button onClick={() => setShowAddDept(false)} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={18} /></button>
            </div>
            <form onSubmit={handleAddDept} className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase mb-1.5">Department Name (EN) *</label>
                <input name="name" required placeholder="e.g. Engineering" className={inputClass} />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase mb-1.5">Department Name (MM)</label>
                <input name="name_mm" placeholder="e.g. အင်ဂျင်နီယာ" className={inputClass} />
              </div>
              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowAddDept(false)} className="flex-1 py-2.5 rounded-xl border text-gray-600 hover:bg-gray-50 font-medium">Cancel</button>
                <button type="submit" className="flex-1 py-2.5 rounded-xl bg-primary text-white hover:bg-primary-700 font-medium">Add</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Branch Modal */}
      {showAddBranch && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => setShowAddBranch(false)}>
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold">Add Branch</h3>
              <button onClick={() => setShowAddBranch(false)} className="p-1.5 hover:bg-gray-100 rounded-lg"><X size={18} /></button>
            </div>
            <form onSubmit={handleAddBranch} className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase mb-1.5">Branch Name *</label>
                <input name="name" required placeholder="e.g. Head Office" className={inputClass} />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase mb-1.5">Address</label>
                <input name="address" placeholder="e.g. No.1, Pyay Road, Yangon" className={inputClass} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-500 uppercase mb-1.5">Latitude</label>
                  <input name="latitude" type="number" step="any" placeholder="16.8661" className={inputClass} />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-500 uppercase mb-1.5">Longitude</label>
                  <input name="longitude" type="number" step="any" placeholder="96.1951" className={inputClass} />
                </div>
              </div>
              <p className="text-xs text-gray-400">GPS coordinates for employee check-in location verification</p>
              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowAddBranch(false)} className="flex-1 py-2.5 rounded-xl border text-gray-600 hover:bg-gray-50 font-medium">Cancel</button>
                <button type="submit" className="flex-1 py-2.5 rounded-xl bg-primary text-white hover:bg-primary-700 font-medium">Add</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
