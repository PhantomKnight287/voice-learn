import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class LanguagesService {
  async getLanguages() {
    return await prisma.language.findMany({
      select: {
        id: true,
        flagUrl: true,
        name: true,
      },
    });
  }
}
