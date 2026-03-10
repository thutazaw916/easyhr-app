'use client';
import { useEffect, useState } from 'react';
import { getAnnouncements, createAnnouncement } from '@/lib/api';
import { Megaphone, Plus, X } from 'lucide-react';
import { useToast } from '@/components/ui/toast';

export default function AnnouncementsPage() {
  const [list, setList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const { toast } = useToast();

  useEffect(() => { load(); }, []);

  const load = async () => {
    setLoading(true);
    try { const res = await getAnnouncements(); setList(res.data || []); } catch {}
    setLoading(false);
  };

  const handleAdd = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    try {
      await createAnnouncement({ title: form.get('title'), content: form.get('content'), priority: form.get('priority') || 'normal' });
      setShowAdd(false);
      toast('Announcement posted!', 'success');
      load();
    } catch { toast('Failed to post announcement', 'error'); }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Announcements</h1>
          <p className="text-[#8E8E93] text-sm mt-1">Company announcements</p>
        </div>
        <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 px-4 py-2.5 bg-primary text-white rounded-xl hover:bg-primary-700 transition font-medium">
          <Plus size={18} /> New Announcement
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" /></div>
      ) : list.length === 0 ? (
        <div className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] p-20 text-center text-[#8E8E93]">
          <Megaphone className="w-12 h-12 mx-auto mb-3 opacity-30" /><p>No announcements yet</p>
        </div>
      ) : (
        <div className="space-y-4">
          {list.map((a: any) => (
            <div key={a.id} className="bg-[#1C1C1E] rounded-2xl border border-[#38383A] p-5">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-semibold text-white">{a.title}</h3>
                  <p className="text-sm text-[#8E8E93] mt-1 whitespace-pre-wrap">{a.content}</p>
                </div>
                <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${a.priority === 'urgent' ? 'bg-red-500/15 text-red-400' : 'bg-blue-500/15 text-blue-400'}`}>
                  {a.priority || 'normal'}
                </span>
              </div>
              <p className="text-xs text-[#8E8E93] mt-3">{new Date(a.created_at).toLocaleDateString()}</p>
            </div>
          ))}
        </div>
      )}

      {showAdd && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={() => setShowAdd(false)}>
          <div className="bg-[#1C1C1E] rounded-2xl p-6 w-full max-w-md border border-[#38383A]" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-white">New Announcement</h3>
              <button onClick={() => setShowAdd(false)} className="p-1.5 hover:bg-[#2C2C2E] rounded-lg text-[#8E8E93]"><X size={18} /></button>
            </div>
            <form onSubmit={handleAdd} className="space-y-3">
              <input name="title" placeholder="Title *" required className="w-full px-4 py-2.5 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white placeholder-[#8E8E93] outline-none focus:ring-2 focus:ring-primary" />
              <textarea name="content" placeholder="Content *" required rows={4} className="w-full px-4 py-2.5 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white placeholder-[#8E8E93] outline-none focus:ring-2 focus:ring-primary resize-none" />
              <select name="priority" className="w-full px-4 py-2.5 rounded-xl border border-[#38383A] bg-[#2C2C2E] text-white outline-none">
                <option value="normal">Normal</option>
                <option value="urgent">Urgent</option>
              </select>
              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowAdd(false)} className="flex-1 py-2.5 rounded-xl border border-[#38383A] text-[#8E8E93] hover:bg-[#2C2C2E] font-medium">Cancel</button>
                <button type="submit" className="flex-1 py-2.5 rounded-xl bg-primary text-white hover:bg-primary-700 font-medium">Post</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
