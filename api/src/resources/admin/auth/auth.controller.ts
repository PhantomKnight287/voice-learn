import { Body, Controller, Get, Header, Headers, Post } from '@nestjs/common';
import { AdminAuthService } from './auth.service';
import { SignInDTO } from 'src/resources/auth/dto/sign-in.dto';

@Controller('admin/auth')
export class AuthController {
  constructor(private readonly authService: AdminAuthService) {}

  @Post('login')
  login(@Body() body: SignInDTO) {
    return this.authService.login(body);
  }

  @Get('hydrate')
  hydrate(@Headers('authorization') auth: string) {
    return this.authService.hydrate(auth);
  }
}
