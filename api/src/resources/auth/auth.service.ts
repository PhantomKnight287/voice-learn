import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { LoginDTO } from './dto/login.dto';
import { hash, verify } from 'argon2';
import { JwtPayload, sign, verify as verifyJWT } from 'jsonwebtoken';
import { ConfigService } from '@nestjs/config';
import { SignupDTO } from './dto/signup.dto';
import { createId } from '@paralleldrive/cuid2';
import { prisma } from 'src/db';

@Injectable()
export class AuthService {
  constructor(private service: ConfigService) {}

  async login(body: LoginDTO) {
    const { password, email } = body;
    const user = await prisma.user.findFirst({
      where: { email: { equals: email, mode: 'insensitive' } },
    });
    if (!user)
      throw new HttpException(
        'No user found with given email.',
        HttpStatus.NOT_FOUND,
      );

    const isPasswordCorrect = await verify(user.password, password);
    if (isPasswordCorrect === false)
      throw new HttpException('Incorrect password', HttpStatus.UNAUTHORIZED);
    const token = sign({ id: user.id }, this.service.get('JWT_SECRET'));
    return {
      token,
      user: {
        name: user.name,
        email: user.email,
        id: user.id,
      },
    };
  }

  async signup(body: SignupDTO) {
    const { email, password, name } = body;
    const existingUser = await prisma.user.findFirst({
      where: { email: { equals: email, mode: 'insensitive' } },
    });

    if (existingUser) {
      throw new HttpException(
        'A user already exists with given email.',
        HttpStatus.CONFLICT,
      );
    }

    const hashedPassword = await hash(password);
    const newUser = await prisma.user.create({
      data: {
        id: `user_${createId()}`,
        name,
        password: hashedPassword,
        email,
      },
    });
    const token = sign({ id: newUser.id }, this.service.get('JWT_SECRET'));
    return {
      token,
      user: {
        id: newUser.id,
        email,
        name,
      },
    };
  }

  async verify(token: string) {
    try {
      const payload = verifyJWT(token, process.env.JWT_SECRET) as JwtPayload;
      const user = await prisma.user.findFirst({
        where: { id: payload.id },
      });
      if (!user) throw new Error('Unauthorized');
      return user;
    } catch (e) {
      throw Error('Unauthorized');
    }
  }

  async hydrate(token: string) {
    try {
      const payload = verifyJWT(token, process.env.JWT_SECRET) as JwtPayload;
      const user = await prisma.user.findFirst({
        where: { id: payload.id },
        omit: { password: true },
      });
      if (!user)
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      return user;
    } catch (e) {
      throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
    }
  }
}
