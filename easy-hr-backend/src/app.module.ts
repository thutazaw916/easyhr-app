import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SupabaseModule } from './supabase/supabase.module';
import { AuthModule } from './auth/auth.module';
import { CompanyModule } from './company/company.module';
import { EmployeeModule } from './employee/employee.module';
import { BranchModule } from './branch/branch.module';
import { DepartmentModule } from './department/department.module';
import { PositionModule } from './position/position.module';
import { AttendanceModule } from './attendance/attendance.module';
import { LeaveModule } from './leave/leave.module';
import { PayrollModule } from './payroll/payroll.module';
import { ChatModule } from './chat/chat.module';
import { AnnouncementModule } from './announcement/announcement.module';
import { SuperAdminModule } from './super-admin/super-admin.module';
import { ChatbotModule } from './chatbot/chatbot.module';
import { BillingModule } from './billing/billing.module';
import { EmailModule } from './email/email.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' }),
    SupabaseModule,
    AuthModule,
    CompanyModule,
    EmployeeModule,
    BranchModule,
    DepartmentModule,
    PositionModule,
    AttendanceModule,
    LeaveModule,
    PayrollModule,
    ChatModule,
    AnnouncementModule,
    SuperAdminModule,
    ChatbotModule,
    BillingModule,
    EmailModule,
  ],
})
export class AppModule {}