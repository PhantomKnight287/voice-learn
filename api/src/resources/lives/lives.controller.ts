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
  @Post('decrement')
  @HttpCode(200)
  @ApiOkResponse({
    schema: {
      example: {
        lives: 'number',
      },
    },
  })
  decreaseHeart(@Auth() auth: User) {
    return this.livesService.removeHeart(auth.id);
  }
}
