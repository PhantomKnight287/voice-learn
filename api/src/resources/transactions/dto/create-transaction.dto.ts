import { TransactionType } from '@prisma/client';
import { IsEnum, IsString } from 'class-validator';

export class CreateTransactionDTO {
  @IsString()
  sku: string;

  @IsString()
  token: string;

  @IsEnum(TransactionType)
  type: TransactionType;
}
