import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ChatService {
  constructor(private supabaseService: SupabaseService) {}

  // ============================================
  // CHANNELS
  // ============================================

  async createChannel(companyId: string, creatorId: string, data: {
    name: string;
    type: 'department' | 'company' | 'direct';
    department_id?: string;
  }) {
    return this.supabaseService.create('chat_channels', {
      company_id: companyId,
      created_by: creatorId,
      ...data,
    });
  }

  async getMyChannels(companyId: string, employeeId: string, departmentId?: string) {
    const db = this.supabaseService.getClient();

    // Get company-wide + department channels + direct channels
    let query = db
      .from('chat_channels')
      .select(`
        *,
        department:department_id(id, name)
      `)
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    const { data, error } = await query;
    if (error) throw error;

    // Filter: company channels + user's department channels
    const channels = (data || []).filter(ch => {
      if (ch.type === 'company') return true;
      if (ch.type === 'department' && ch.department_id === departmentId) return true;
      return false;
    });

    // Get unread counts
    for (const channel of channels) {
      const { data: readStatus } = await db
        .from('chat_read_status')
        .select('last_read_at')
        .eq('channel_id', channel.id)
        .eq('employee_id', employeeId)
        .single();

      const lastRead = readStatus?.last_read_at || '1970-01-01';

      const { count } = await db
        .from('chat_messages')
        .select('*', { count: 'exact', head: true })
        .eq('channel_id', channel.id)
        .eq('is_deleted', false)
        .gt('created_at', lastRead);

      channel.unread_count = count || 0;

      // Get last message
      const { data: lastMsg } = await db
        .from('chat_messages')
        .select('message, created_at, sender:sender_id(first_name)')
        .eq('channel_id', channel.id)
        .eq('is_deleted', false)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      channel.last_message = lastMsg;
    }

    return channels;
  }

  // ============================================
  // MESSAGES
  // ============================================

  async sendMessage(channelId: string, senderId: string, data: {
    message?: string;
    message_type?: string;
    file_url?: string;
  }) {
    const db = this.supabaseService.getClient();

    // Verify channel exists
    const channel = await this.supabaseService.findOne('chat_channels', channelId);
    if (!channel) throw new NotFoundException('Channel not found');

    const { data: msg, error } = await db
      .from('chat_messages')
      .insert({
        channel_id: channelId,
        sender_id: senderId,
        message: data.message,
        message_type: data.message_type || 'text',
        file_url: data.file_url,
      })
      .select(`
        *,
        sender:sender_id(id, first_name, last_name, profile_photo_url)
      `)
      .single();

    if (error) throw error;
    return msg;
  }

  async getMessages(channelId: string, employeeId: string, page: number = 1, limit: number = 50) {
    const db = this.supabaseService.getClient();
    const offset = (page - 1) * limit;

    const { data, count, error } = await db
      .from('chat_messages')
      .select(`
        *,
        sender:sender_id(id, first_name, last_name, profile_photo_url)
      `, { count: 'exact' })
      .eq('channel_id', channelId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    // Update read status
    await db.from('chat_read_status').upsert({
      channel_id: channelId,
      employee_id: employeeId,
      last_read_at: new Date().toISOString(),
    });

    return {
      messages: (data || []).reverse(),
      pagination: { total: count, page, limit },
    };
  }

  async pinMessage(messageId: string, pin: boolean) {
    return this.supabaseService.update('chat_messages', messageId, { is_pinned: pin });
  }

  async deleteMessage(messageId: string, senderId: string) {
    const db = this.supabaseService.getClient();
    const { data, error } = await db
      .from('chat_messages')
      .update({ is_deleted: true })
      .eq('id', messageId)
      .eq('sender_id', senderId)
      .select()
      .single();
    if (error) throw new NotFoundException('Message not found or not yours');
    return data;
  }

  // ============================================
  // AUTO-CREATE CHANNELS FOR COMPANY
  // ============================================

  async initCompanyChannels(companyId: string, creatorId: string) {
    const db = this.supabaseService.getClient();

    // Create company-wide channel
    await db.from('chat_channels').insert({
      company_id: companyId,
      name: 'General',
      type: 'company',
      created_by: creatorId,
    });

    // Create department channels
    const { data: departments } = await db
      .from('departments')
      .select('id, name')
      .eq('company_id', companyId)
      .eq('is_active', true);

    if (departments) {
      for (const dept of departments) {
        await db.from('chat_channels').insert({
          company_id: companyId,
          name: dept.name,
          type: 'department',
          department_id: dept.id,
          created_by: creatorId,
        });
      }
    }

    return { message: 'Chat channels initialized' };
  }
}