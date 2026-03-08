// src/branch/branch.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class BranchService {
  constructor(private supabaseService: SupabaseService) {}

  async createBranch(companyId: string, data: any) {
    return this.supabaseService.create('branches', { company_id: companyId, ...data });
  }

  async listBranches(companyId: string) {
    return this.supabaseService.findAll('branches', { company_id: companyId, is_active: true });
  }

  async getBranch(companyId: string, branchId: string) {
    const branch = await this.supabaseService.findOneBy('branches', { id: branchId, company_id: companyId });
    if (!branch) throw new NotFoundException('Branch not found');
    return branch;
  }

  async updateBranch(companyId: string, branchId: string, data: any) {
    await this.getBranch(companyId, branchId);
    return this.supabaseService.update('branches', branchId, data);
  }

  // Update GPS location and radius for check-in
  async updateGpsSettings(companyId: string, branchId: string, data: {
    latitude: number;
    longitude: number;
    radius_meters: number;
  }) {
    return this.updateBranch(companyId, branchId, data);
  }

  // Toggle QR code for branch
  async toggleQrCode(companyId: string, branchId: string, enabled: boolean) {
    const qrSecret = enabled ? this.generateQrSecret() : null;
    return this.updateBranch(companyId, branchId, {
      qr_code_enabled: enabled,
      qr_secret_key: qrSecret,
    });
  }

  private generateQrSecret(): string {
    return 'EHR-' + Math.random().toString(36).substring(2, 15) + Date.now().toString(36);
  }
}
