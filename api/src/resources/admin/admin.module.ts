import { Module } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { AuthModule } from './auth/auth.module';
import { AdminAuthService } from './auth/auth.service';

@Module({
  controllers: [AdminController],
  providers: [AdminService,AdminAuthService],
  imports: [AuthModule,],
})
export class AdminModule {}
