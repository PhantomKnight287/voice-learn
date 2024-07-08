import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { CreateStackDTO } from './dto/create-stack.dto';
import { createId } from '@paralleldrive/cuid2';
import { CreateNoteDTO } from './dto/create-note.dto';

@Injectable()
export class RecallsService {
  async getStacks(userId: string, page: number) {
    const stacks = await prisma.stack.paginate({
      page,
      limit: 20,
      where: {
        userId,
      },
      include: {
        _count: {
          select: {
            notes: true,
          },
        },
      },
      orderBy: [
        {
          createdAt: 'desc',
        },
      ],
    });
    return stacks.result;
  }

  async createStack(body: CreateStackDTO, userId: string) {
    const stack = await prisma.stack.create({
      data: {
        id: `stack_${createId()}`,
        name: body.name,
        description: body.description,
        userId,
      },
    });
    return {
      id: stack.id,
    };
  }

  async createNote(body: CreateNoteDTO, stackId: string, userId: string) {
    const stack = await prisma.stack.findFirst({
      where: { userId, id: stackId },
    });
    if (!stack)
      throw new HttpException('No Stack found.', HttpStatus.NOT_FOUND);
    const note = await prisma.note.create({
      data: {
        description: body.description,
        title: body.title,
        id: `note_${createId()}`,
        stackId,
      },
    });
    return {
      id: note.id,
    };
  }

  async deleteStack(stackId: string, userId: string) {
    const stack = await prisma.stack.findFirst({
      where: { userId, id: stackId },
    });
    if (!stack)
      throw new HttpException('No Stack found.', HttpStatus.NOT_FOUND);
    await prisma.stack.delete({ where: { id: stack.id } });
    return {
      id: stackId,
    };
  }

  async listNotes(stackId: string, userId: string, page: number) {
    const notes = await prisma.note.paginate({
      where: {
        stack: {
          id: stackId,
          userId,
        },
      },
      page,
      limit: 20,
      orderBy: [
        {
          createdAt: 'desc',
        },
      ],
    });
    return notes.result;
  }

  async getStackNames(userId: string) {
    const stacks = await prisma.stack.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }],
      select: {
        id: true,
        name: true,
      },
    });
    return stacks;
  }
}
