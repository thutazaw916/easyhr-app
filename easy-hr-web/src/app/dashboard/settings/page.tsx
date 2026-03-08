'use client';
import { useEffect, useState } from 'react';
import { getCompanySettings, updateCompanySettings, getDepartments, getBranches } from '@/lib/api';
import { Settings, Save, Building2, Users } from 'lucide-react';

export default function SettingsPage() {
  const [settings, setSettings] = useState<any>(null);
  const [departments, setDepartments] = useState<any[]>([]);
  const [branches, setBranches] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

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

  if (loading) return <div className="flex justify-center py-20"><div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" /></div>;

  return (
    <div className="max-w-4xl">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Company Settings</h1>

      {/* Work Hours */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2"><Settings size={20} /> Work Schedule</h2>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-600 mb-1">Work Start Time</label>
            <input type="time" value={settings?.work_start_time || '09:00'} onChange={(e) => setSettings({...settings, work_start_time: e.target.value})}
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-600 mb-1">Work End Time</label>
            <input type="time" value={settings?.work_end_time || '17:00'} onChange={(e) => setSettings({...settings, work_end_time: e.target.value})}
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-600 mb-1">Late Threshold (min)</label>
            <input type="number" value={settings?.late_threshold_minutes || 15} onChange={(e) => setSettings({...settings, late_threshold_minutes: Number(e.target.value)})}
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-600 mb-1">Check-in Radius (m)</label>
            <input type="number" value={settings?.checkin_radius_meters || 200} onChange={(e) => setSettings({...settings, checkin_radius_meters: Number(e.target.value)})}
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-primary" />
          </div>
        </div>
        <button onClick={handleSave} disabled={saving}
          className="mt-4 flex items-center gap-2 px-5 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition font-medium disabled:opacity-50">
          <Save size={16} /> {saving ? 'Saving...' : 'Save Settings'}
        </button>
      </div>

      {/* Departments */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2"><Users size={20} /> Departments ({departments.length})</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
          {departments.map((d: any) => (
            <div key={d.id} className="p-3 rounded-xl bg-gray-50 border border-gray-100">
              <p className="font-medium text-sm">{d.name}</p>
              <p className="text-xs text-gray-400">{d.name_mm || ''}</p>
            </div>
          ))}
          {departments.length === 0 && <p className="text-gray-400 text-sm col-span-3">No departments yet</p>}
        </div>
      </div>

      {/* Branches */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6">
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2"><Building2 size={20} /> Branches ({branches.length})</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
          {branches.map((b: any) => (
            <div key={b.id} className="p-3 rounded-xl bg-gray-50 border border-gray-100">
              <p className="font-medium text-sm">{b.name}</p>
              <p className="text-xs text-gray-400">{b.address || ''}</p>
            </div>
          ))}
          {branches.length === 0 && <p className="text-gray-400 text-sm col-span-3">No branches yet</p>}
        </div>
      </div>
    </div>
  );
}
