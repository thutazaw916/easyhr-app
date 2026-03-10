'use client';
import { useEffect, useState } from 'react';
import { getWhitelist, addToWhitelist, removeFromWhitelist, toggleWhitelist } from '@/lib/api';

interface WhitelistEntry {
  id: string;
  email: string;
  note?: string;
  created_at?: string;
}

export default function WhitelistPage() {
  const [entries, setEntries] = useState<WhitelistEntry[]>([]);
  const [enabled, setEnabled] = useState(false);
  const [loading, setLoading] = useState(true);
  const [email, setEmail] = useState('');
  const [note, setNote] = useState('');
  const [adding, setAdding] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await getWhitelist();
      setEntries(res.whitelist || []);
      setEnabled(res.enabled || false);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    }
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setAdding(true);
    setError('');
    try {
      await addToWhitelist(email.trim(), note.trim() || undefined);
      setEmail('');
      setNote('');
      load();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to add');
    }
    setAdding(false);
  };

  const handleRemove = async (entry: WhitelistEntry) => {
    if (!confirm(`Remove "${entry.email}" from whitelist?`)) return;
    try {
      await removeFromWhitelist(entry.id);
      load();
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : 'Failed');
    }
  };

  const handleToggle = async () => {
    const newState = !enabled;
    const action = newState ? 'enable' : 'disable';
    if (!confirm(`${action.charAt(0).toUpperCase() + action.slice(1)} email whitelist?\n\n${newState ? 'Only whitelisted emails will be able to register.' : 'Anyone will be able to register.'}`)) return;
    try {
      await toggleWhitelist(newState);
      setEnabled(newState);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : 'Failed');
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">Email Whitelist</h1>
          <p className="text-sm text-[#8E8E93] mt-1">Control which emails can register as companies</p>
        </div>
        <button
          onClick={handleToggle}
          className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
            enabled
              ? 'bg-emerald-500/15 text-emerald-400 hover:bg-emerald-500/25'
              : 'bg-[#2C2C2E] text-[#8E8E93] hover:bg-[#38383A]'
          }`}
        >
          {enabled ? '✅ Whitelist ON' : '⬜ Whitelist OFF'}
        </button>
      </div>

      {!enabled && (
        <div className="mb-6 p-4 bg-amber-500/10 border border-amber-500/20 rounded-xl text-sm text-amber-400">
          ⚠️ Whitelist is <strong>disabled</strong>. Anyone can register. Enable it to restrict signups to whitelisted emails only.
        </div>
      )}

      {enabled && (
        <div className="mb-6 p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-sm text-emerald-400">
          ✅ Whitelist is <strong>enabled</strong>. Only emails listed below can register new companies.
        </div>
      )}

      {error && <p className="text-red-400 bg-red-500/15 p-3 rounded-xl mb-4 text-sm">{error}</p>}

      {/* Add Email Form */}
      <form onSubmit={handleAdd} className="flex gap-3 mb-6">
        <input
          type="email"
          placeholder="Email address (e.g. user@gmail.com)"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="flex-1 px-4 py-2.5 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white placeholder-[#8E8E93] focus:ring-2 focus:ring-primary outline-none text-sm"
        />
        <input
          type="text"
          placeholder="Note (optional)"
          value={note}
          onChange={(e) => setNote(e.target.value)}
          className="w-48 px-4 py-2.5 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white placeholder-[#8E8E93] focus:ring-2 focus:ring-primary outline-none text-sm"
        />
        <button
          type="submit"
          disabled={adding}
          className="px-5 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition text-sm font-medium disabled:opacity-50"
        >
          {adding ? 'Adding...' : '+ Add'}
        </button>
      </form>

      {/* Whitelist Table */}
      {loading ? (
        <p className="text-[#8E8E93] text-sm">Loading...</p>
      ) : (
        <div className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-[#2C2C2E] border-b border-[#38383A]">
                <th className="text-left px-6 py-4 font-medium text-[#8E8E93]">Email</th>
                <th className="text-left px-6 py-4 font-medium text-[#8E8E93]">Note</th>
                <th className="text-left px-6 py-4 font-medium text-[#8E8E93]">Added</th>
                <th className="text-right px-6 py-4 font-medium text-[#8E8E93]">Action</th>
              </tr>
            </thead>
            <tbody>
              {entries.map((entry) => (
                <tr key={entry.id} className="border-b border-[#2C2C2E] hover:bg-[#2C2C2E]/50 transition">
                  <td className="px-6 py-4 font-medium text-white">{entry.email}</td>
                  <td className="px-6 py-4 text-[#8E8E93]">{entry.note || '-'}</td>
                  <td className="px-6 py-4 text-[#8E8E93] text-xs">
                    {entry.created_at ? new Date(entry.created_at).toLocaleDateString() : '-'}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button
                      onClick={() => handleRemove(entry)}
                      className="text-xs text-red-500 hover:underline"
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              ))}
              {entries.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-6 py-8 text-center text-[#8E8E93]">
                    No emails in whitelist yet. Add emails above.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      <p className="text-xs text-[#8E8E93] mt-4">
        Total: {entries.length} email{entries.length !== 1 ? 's' : ''} whitelisted
      </p>
    </div>
  );
}
