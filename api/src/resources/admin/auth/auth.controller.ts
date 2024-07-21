import { Body, Controller, Get, Header, Headers } from '@nestjs/common';
import { AdminAuthService } from './auth.service';
import { SignInDTO } from 'src/resources/auth/dto/sign-in.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AdminAuthService) {}

  @Get('login')
  login(@Body() body: SignInDTO) {
    return this.authService.login(body);
  }

  @Get('hydrate')
  hydrate(@Headers('authorization') auth: string) {
    return this.authService.hydrate(auth);
  }
}
