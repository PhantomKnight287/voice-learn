import { Controller, Get, ParseIntPipe, Query } from '@nestjs/common';
import { LeaderboardService } from './leaderboard.service';
import { ApiHeader, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';

@Controller('leaderboard')
@ApiTags('Leaderboard')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
export class LeaderboardController {
  constructor(private readonly leaderboardService: LeaderboardService) {}

  @Get()
  @ApiQuery({
    name: 'page',
    type: Number,
    required: true,
  })
  @ApiOperation({})
  getLeaderboard(@Query('page', ParseIntPipe) page: number) {
    return this.leaderboardService.getLeaderBoard(page);
  }
}
