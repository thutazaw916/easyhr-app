import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class NotificationService {
  constructor(private supabaseService: SupabaseService) {}

  async create(data: {
    company_id: string;
    recipient_id: string;
    sender_id?: string;
    type: string;
    title: string;
    title_mm?: string;
    body?: string;
    body_mm?: string;
    data?: Record<string, any>;
  }) {
    const db = this.supabaseService.getClient();
    const { data: notification, error } = await db
      .from('notifications')
      .insert(data)
      .select()
      .single();
    if (error) {
      console.error('Failed to create notification:', error);
      return null;
    }
    return notification;
  }

  async notifyAdmins(companyId: string, notification: {
    sender_id?: string;
    type: string;
    title: string;
    title_mm?: string;
    body?: string;
    body_mm?: string;
    data?: Record<string, any>;
  }) {
    const db = this.supabaseService.getClient();

    // Find all admins (owner, hr_manager) in the company
    const { data: admins } = await db
      .from('employees')
      .select('id')
      .eq('company_id', companyId)
      .in('role', ['owner', 'hr_manager'])
      .eq('is_active', true);

    if (!admins || admins.length === 0) return;

    // Create notification for each admin
    const notifications = admins
      .filter((a: any) => a.id !== notification.sender_id)
      .map((admin: any) => ({
        company_id: companyId,
        recipient_id: admin.id,
        ...notification,
      }));

    if (notifications.length === 0) return;

    const { error } = await db.from('notifications').insert(notifications);
    if (error) console.error('Failed to notify admins:', error);
  }

  async getMyNotifications(employeeId: string, limit = 50) {
    const db = this.supabaseService.getClient();
    const { data, error } = await db
      .from('notifications')
      .select('*')
      .eq('recipient_id', employeeId)
      .order('created_at', { ascending: false })
      .limit(limit);
    if (error) throw error;
    return data;
  }

  async getUnreadCount(employeeId: string) {
    const db = this.supabaseService.getClient();
    const { count, error } = await db
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('recipient_id', employeeId)
      .eq('is_read', false);
    if (error) throw error;
    return { unread_count: count || 0 };
  }

  async markAsRead(employeeId: string, notificationId?: string) {
    const db = this.supabaseService.getClient();
    let query = db.from('notifications').update({ is_read: true }).eq('recipient_id', employeeId);
    if (notificationId) {
      query = query.eq('id', notificationId);
    }
    const { error } = await query;
    if (error) throw error;
    return { message: 'Marked as read' };
  }
}
