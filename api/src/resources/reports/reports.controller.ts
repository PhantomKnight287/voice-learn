import { Body, Controller, Param, Post } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { ReportQuestionDTO } from './dto/report-question.dto';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post('question/:id')
  reportQuestion(
    @Body() body: ReportQuestionDTO,
    @Param('id') id: string,
    @Auth() auth: User,
  ) {
    return this.reportsService.reportQuestion(body, id, auth.id);
  }
}
