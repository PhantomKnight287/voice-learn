import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { OnboardingService } from './onboarding.service';
import {
  ApiHeader,
  ApiOkResponse,
  ApiOperation,
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

  @ApiOperation({})
  @Post('')
  @ApiOkResponse({
    schema: { example: { id: 'string' } },
  })
  completeOnboarding(@Body() body: CompleteOnBoardingDTO, @Auth() user: User) {
    return this.onboardingService.completeOnboarding(body, user.id);
  }

  @ApiOperation({
    summary: 'Get queue status',
    description: 'Get queue status',
  })
  @ApiOkResponse({
    schema: {
      example: {
        generated: 'boolean',
        position: 'number | null',
      },
    },
  })
  @Get(':id')
  getOnBoardingStatus(@Param('id') id: string, @Auth() user: User) {
    return this.onboardingService.getOnBoardingStatus(id, user.id);
  }

  @ApiOperation({
    description: 'Get learning path',
    summary: 'Get learning path',
  })
  @Get()
  getLearningPath(@Auth() user: User) {
    return this.onboardingService.getLearningPath(user.id);
  }
}
