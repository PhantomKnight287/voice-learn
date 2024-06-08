import { Controller, Get } from '@nestjs/common';
import { ProfileService } from './profile.service';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('profile')
@ApiTags('Profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @ApiOperation({})
  @Get('@me')
  getMyProfile(@Auth() auth: User) {
    return this.profileService.getMyProfile(auth.id);
  }
}
