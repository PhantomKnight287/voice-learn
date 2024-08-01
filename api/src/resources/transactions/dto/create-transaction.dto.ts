import { TransactionType, Platform } from '@prisma/client';
import { IsEnum, IsOptional, IsString } from 'class-validator';

export class CreateTransactionDTO {
  @IsString()
  sku: string;

  @IsString()
  token: string;

  @IsEnum(TransactionType)
  type: TransactionType;

  @IsEnum(Platform)
  platform: Platform;

  @IsString()
  @IsOptional()
  purchaseId: string;
}
