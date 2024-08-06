import { Module } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { AuthModule } from './auth/auth.module';
import { AdminAuthService } from './auth/auth.service';
import { UsersModule } from './users/users.module';
import { ReportsModule } from './reports/reports.module';

@Module({
  controllers: [AdminController],
  providers: [AdminService,AdminAuthService],
  imports: [AuthModule, UsersModule, ReportsModule,],
})
export class AdminModule {}
