import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class ReportsService {
  async getReports(page: number, limit: number = 50) {
    const data = await prisma.report.paginate({
      limit,
      page,
      orderBy: [
        {
          createdAt: 'desc',
        },
      ],
      select: {
        author: {
          select: {
            name: true,
            id: true,
          },
        },
        content: true,
        id: true,
        status: true,
        title: true,
        question: {
          select: {
            id: true,
          },
        },
        createdAt: true,
      },
    });
    return {
      results: data.result,
      pages: data.totalPages,
    };
  }
}
