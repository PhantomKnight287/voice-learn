import { PrismaClient } from '@prisma/client';
import extension from 'prisma-paginate';
const p = new PrismaClient({
  errorFormat: 'colorless',
  log: ['error', 'info', 'warn'],
});

export const prisma = p.$extends(extension);
