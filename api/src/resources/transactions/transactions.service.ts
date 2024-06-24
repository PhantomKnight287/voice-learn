import { Injectable } from '@nestjs/common';
import { CreateTransactionDTO } from './dto/create-transaction.dto';
import { prisma } from 'src/db';
import { PRODUCTS } from 'src/constants';
import { Transaction } from '@prisma/client';

@Injectable()
export class TransactionsService {
  async createTransaction(body: CreateTransactionDTO, userId: string) {
    let transaction: Transaction;

    transaction = await prisma.transaction.findFirst({
      where: { purchaseToken: body.token },
    });
    if (!transaction) {
      transaction = await prisma.transaction.create({
        data: {
          purchaseToken: body.token,
          sku: body.sku,
          type: body.type,
          userId,
        },
      });
    }
    if (!transaction.userId) {
      transaction = await prisma.transaction.update({
        where: { id: transaction.id },
        data: { userId },
      });
    }

    if (
      transaction.userId &&
      transaction.completed == false &&
      transaction.userUpdated == false
    ) {
      if (transaction.type === 'one_time_product') {
        await prisma.$transaction([
          prisma.user.update({
            where: {
              id: transaction.userId,
            },
            data: {
              emeralds: {
                increment: PRODUCTS[transaction.sku] ?? 0,
              },
            },
          }),
          prisma.transaction.update({
            where: { id: transaction.id },
            data: { userUpdated: true, completed: true },
          }),
        ]);
      } else {
        await prisma.$transaction([
          prisma.user.update({
            where: {
              id: transaction.userId,
            },
            data: {
              tier: 'premium',
            },
          }),
          prisma.transaction.update({
            where: { id: transaction.id },
            data: { userUpdated: true, completed: true },
          }),
        ]);
      }
    }
    return {
      id: transaction.id,
    };
  }
}
