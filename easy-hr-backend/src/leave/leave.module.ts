import { Module } from '@nestjs/common';
import { LeaveService } from './leave.service';
import { LeaveController } from './leave.controller';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [NotificationModule],
  controllers: [LeaveController],
  providers: [LeaveService],
  exports: [LeaveService],
})
export class LeaveModule {}
