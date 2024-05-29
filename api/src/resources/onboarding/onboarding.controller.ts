import { Body, Controller, Get, Post } from '@nestjs/common';
import { OnboardingService } from './onboarding.service';
import {
  ApiHeader,
  ApiOkResponse,
  ApiProperty,
  ApiTags,
} from '@nestjs/swagger';
import { CompleteOnBoardingDTO } from './dto/complete-onboarding.dto';

import { User } from '@prisma/client';
import { Auth } from 'src/decorators/auth/auth.decorator';

@Controller('onboarding')
@ApiTags('Onboarding')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @ApiProperty({})
  @Post('')
  @ApiOkResponse({
    schema: { example: { id: 'string' } },
  })
  completeOnboarding(@Body() body: CompleteOnBoardingDTO, @Auth() user: User) {
    return this.onboardingService.completeOnboarding(body, user.id);
  }
}
