import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class TutorialsService {
  async getTutorialsStatus(userId: string) {
    const status = await prisma.user.findFirst({
      where: { id: userId },
      select: {
        chatScreenTutorialShown: true,
        homeScreenTutorialShown: true,
      },
    });
    return status;
  }

  async markHomeScreenTutorialShown(userId: string) {
    await prisma.user.update({
      where: { id: userId },
      data: { homeScreenTutorialShown: true },
    });
    return { id: userId };
  }

  async markChatScreenTutorialAsShown(id: string) {
    await prisma.user.update({
      where: { id },
      data: { chatScreenTutorialShown: true },
    });
    return {
      id,
    };
  }
}
