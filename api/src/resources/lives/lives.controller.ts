import { Controller, HttpCode, Post } from '@nestjs/common';
import { LivesService } from './lives.service';
import {
  ApiHeader,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('lives')
@ApiTags('Lives')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
export class LivesController {
  constructor(private readonly livesService: LivesService) {}

  @ApiOperation({})
  @Post('add-one')
  @HttpCode(200)
  @ApiOkResponse({
    schema: {
      example: {
        lives: 'number',
        emeralds: 'number',
      },
    },
  })
  addOne(@Auth() auth: User) {
    return this.livesService.buyOneLife(auth.id);
  }

  @ApiOperation({})
  @Post('refill')
  @HttpCode(200)
  @ApiOkResponse({
    schema: {
      example: {
        lives: 'number',
        emeralds: 'number',
      },
    },
  })
  refill(@Auth() auth: User) {
    return this.livesService.refillAllLives(auth.id);
  }
}
