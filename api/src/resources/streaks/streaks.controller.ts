import { Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { StreaksService } from './streaks.service';
import { ApiHeader, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('streaks')
@ApiTags('Streaks')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
export class StreaksController {
  constructor(private readonly streaksService: StreaksService) {}

  @ApiOperation({})
  @Get(':year/:month')
  @ApiParam({
    name: 'year',
    type: Number,
    required: true,
  })
  @ApiParam({
    name: 'month',
    type: Number,
    required: true,
  })
  async getStreaks(
    @Auth() auth: User,
    @Param('year', ParseIntPipe) year: number,
    @Param('month', ParseIntPipe) month: number,
  ) {
    return await this.streaksService.getUserStreaks(auth.id, month, year);
  }

  @ApiOperation({})
  @Get('shields')
  getStreakShields(@Auth() auth: User) {
    return this.streaksService.getStreakShields(auth.id);
  }

  @Post('shields/one')
  buyOneStreakShield(@Auth() auth: User) {
    return this.streaksService.buyOneShield(auth.id);
  }

  @Post('shields/refill')
  refillStreakShield(@Auth() auth: User) {
    return this.streaksService.refillShields(auth.id);
  }
}
