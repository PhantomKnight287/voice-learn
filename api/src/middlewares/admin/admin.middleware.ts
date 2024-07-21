import { NextFunction, Request, Response } from 'express';

import {
  HttpException,
  HttpStatus,
  Injectable,
  NestMiddleware,
} from '@nestjs/common';

import { User } from '@prisma/client';
import { AdminAuthService } from 'src/resources/admin/auth/auth.service';

@Injectable()
export class AdminAuthMiddleware implements NestMiddleware {
  constructor(private readonly authService: AdminAuthService) {}
  async use(
    req: Request & {
      auth: Partial<User>;
    },
    res: Response,
    next: NextFunction,
  ) {
    try {
      const token = req.headers.authorization;
      if (!token) throw Error();
      req.auth = await this.authService.hydrate(
        token.startsWith('Bearer ') ? token.replaceAll('Bearer ', '') : token,
      );
      next();
    } catch (e) {
      throw new HttpException(
        'Missing or Expired Token',
        HttpStatus.UNAUTHORIZED,
      );
    }
  }
}
