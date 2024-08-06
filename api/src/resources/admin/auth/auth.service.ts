import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { sign, verify } from 'jsonwebtoken';
import { prisma } from 'src/db';
import { SignInDTO } from 'src/resources/auth/dto/sign-in.dto';

@Injectable()
export class AdminAuthService {
  async login(body: SignInDTO) {
    const user = await prisma.user.findFirst({ where: { email: body.email } });
    if (!user) throw new HttpException('No user found', HttpStatus.NOT_FOUND);
    if (user.id !== process.env.ADMIN_USER_ID)
      throw new HttpException(
        "Provided Credentials don't belong to an admin.",
        HttpStatus.NOT_FOUND,
      );
    const token = sign({ id: user.id }, process.env.RESET_PASSWORD_SECRET);
    return {
      id: user.id,
      name: user.name,
      token,
    };
  }

  async validate(userId: string) {
    const user = await prisma.user.findFirst({ where: { id: userId } });
    if (!user) throw new HttpException('No user found', HttpStatus.NOT_FOUND);
    if (user.id !== process.env.ADMIN_USER_ID)
      throw new HttpException(
        "Provided Credentials don't belong to an admin.",
        HttpStatus.NOT_FOUND,
      );
    return {
      id: user.id,
      name: user.name,
    };
  }

  async hydrate(token: string) {
    try {
      const data = verify(
        token.replace('Bearer ', ''),
        process.env.RESET_PASSWORD_SECRET,
      );
      const userId = (data as any).id;
      const user = await prisma.user.findFirst({ where: { id: userId } });
      if (!user) throw new HttpException('No user found', HttpStatus.NOT_FOUND);
      if (user.id !== process.env.ADMIN_USER_ID)
        throw new HttpException(
          "Provided Credentials don't belong to an admin.",
          HttpStatus.NOT_FOUND,
        );
      return {
        id: user.id,
        name: user.name,
      };
    } catch (e) {
      if (e instanceof HttpException) {
        throw new HttpException(e.message, e.getStatus());
      }

      throw new HttpException('Invalid Token', HttpStatus.UNAUTHORIZED);
    }
  }
}
