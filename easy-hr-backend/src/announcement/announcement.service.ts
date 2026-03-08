import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class AnnouncementService {
  constructor(private supabaseService: SupabaseService) {}

  async create(companyId: string, creatorId: string, data: {
    title: string;
    title_mm?: string;
    content: string;
    content_mm?: string;
    priority?: string;
    target_type?: string;
    target_department_id?: string;
    attachment_url?: string;
    expires_at?: string;
  }) {
    const db = this.supabaseService.getClient();
    const { data: announcement, error } = await db
      .from('announcements')
      .insert({
        company_id: companyId,
        created_by: creatorId,
        ...data,
        priority: data.priority || 'normal',
        target_type: data.target_type || 'all',
      })
      .select(`*, creator:created_by(id, first_name, last_name)`)
      .single();
    if (error) throw error;
    return announcement;
  }

  async getAll(companyId: string, employeeId: string, departmentId?: string) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('announcements')
      .select(`*, creator:created_by(id, first_name, last_name, profile_photo_url)`)
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('is_pinned', { ascending: false })
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Filter by target
    let results = (data || []).filter(a => {
      if (a.target_type === 'all') return true;
      if (a.target_type === 'department' && a.target_department_id === departmentId) return true;
      return false;
    });

    // Check read status
    const { data: readStatus } = await db
      .from('announcement_reads')
      .select('announcement_id')
      .eq('employee_id', employeeId);

    const readIds = (readStatus || []).map((r: any) => r.announcement_id);
    results = results.map(a => ({ ...a, is_read: readIds.includes(a.id) }));

    return results;
  }

  async getOne(id: string) {
    const db = this.supabaseService.getClient();
    const { data, error } = await db
      .from('announcements')
      .select(`*, creator:created_by(id, first_name, last_name, profile_photo_url)`)
      .eq('id', id)
      .single();
    if (error) throw new NotFoundException('Announcement not found');
    return data;
  }

  async markAsRead(announcementId: string, employeeId: string) {
    const db = this.supabaseService.getClient();
    await db.from('announcement_reads').upsert({
      announcement_id: announcementId,
      employee_id: employeeId,
      read_at: new Date().toISOString(),
    });
    return { message: 'Marked as read' };
  }

  async pin(id: string, pin: boolean) {
    return this.supabaseService.update('announcements', id, { is_pinned: pin });
  }

  async remove(id: string) {
    return this.supabaseService.update('announcements', id, { is_active: false });
  }
}