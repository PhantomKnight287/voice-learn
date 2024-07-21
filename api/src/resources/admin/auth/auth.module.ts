import { Module } from '@nestjs/common';
import { AdminAuthService } from './auth.service';
import { AuthController } from './auth.controller';

@Module({
  controllers: [AuthController],
  providers: [AdminAuthService],
  exports:[AdminAuthService]
})
export class AuthModule {}
