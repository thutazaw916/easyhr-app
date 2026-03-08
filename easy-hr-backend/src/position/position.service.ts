import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class PositionService {
  constructor(private supabaseService: SupabaseService) {}

  async create(companyId: string, data: any) {
    return this.supabaseService.create('positions', { company_id: companyId, ...data });
  }

  async list(companyId: string, departmentId?: string) {
    const db = this.supabaseService.getClient();
    let query = db
      .from('positions')
      .select('*, department:department_id(id, name)')
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('level', { ascending: false });

    if (departmentId) query = query.eq('department_id', departmentId);

    const { data, error } = await query;
    if (error) throw error;
    return data;
  }

  async update(companyId: string, id: string, data: any) {
    const existing = await this.supabaseService.findOneBy('positions', { id, company_id: companyId });
    if (!existing) throw new NotFoundException('Position not found');
    return this.supabaseService.update('positions', id, data);
  }

  async delete(companyId: string, id: string) {
    return this.update(companyId, id, { is_active: false });
  }
}