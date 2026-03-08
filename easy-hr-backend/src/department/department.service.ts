// src/department/department.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class DepartmentService {
  constructor(private supabaseService: SupabaseService) {}

  async create(companyId: string, data: any) {
    return this.supabaseService.create('departments', { company_id: companyId, ...data });
  }

  async list(companyId: string) {
    const db = this.supabaseService.getClient();
    const { data, error } = await db
      .from('departments')
      .select('*, parent:parent_department_id(id, name)')
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('name');
    if (error) throw error;
    return data;
  }

  async get(companyId: string, id: string) {
    const dept = await this.supabaseService.findOneBy('departments', { id, company_id: companyId });
    if (!dept) throw new NotFoundException('Department not found');
    return dept;
  }

  async update(companyId: string, id: string, data: any) {
    await this.get(companyId, id);
    return this.supabaseService.update('departments', id, data);
  }

  async delete(companyId: string, id: string) {
    await this.get(companyId, id);
    return this.supabaseService.update('departments', id, { is_active: false });
  }
}
