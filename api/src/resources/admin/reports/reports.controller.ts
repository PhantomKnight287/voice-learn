import { Controller, Get, ParseIntPipe, Query } from '@nestjs/common';
import { ReportsService } from './reports.service';

@Controller('admin/reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}
  @Get()
  getReports(
    @Query('page', ParseIntPipe) page: number,
    @Query('limit', ParseIntPipe) limit: number,
  ) {
    return this.reportsService.getReports(page, limit);
  }
}
