import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { SignInDTO } from './dto/sign-in.dto';
import { hash, verify } from 'argon2';
import { JwtPayload, sign, verify as verifyJWT } from 'jsonwebtoken';
import { ConfigService } from '@nestjs/config';
import { SignupDTO } from './dto/signup.dto';
import { createId } from '@paralleldrive/cuid2';
import { prisma } from 'src/db';
import moment from 'moment';
import { UpdatePasswordDTO } from './dto/update-password.dto';
import { generateTimestamps, parseOffset } from 'src/lib/time';

@Injectable()
export class AuthService {
  constructor(private service: ConfigService) {}

  async signIn(body: SignInDTO) {
    const { password, email, timezone, timeZoneOffset } = body;
    const user = await prisma.user.findFirst({
      where: { email: { equals: email, mode: 'insensitive' } },
      include: {
        _count: {
          select: { paths: true },
        },
      },
    });
    if (!user)
      throw new HttpException(
        'No user found with given email.',
        HttpStatus.NOT_FOUND,
      );

    const isPasswordCorrect = await verify(user.password, password);
    if (isPasswordCorrect === false)
      throw new HttpException('Incorrect password', HttpStatus.UNAUTHORIZED);

    delete user.password;
    const token = sign({ id: user.id }, this.service.get('JWT_SECRET'));
    console.log(user);
    const { currentDateInGMT, nextDateInGMT } = generateTimestamps(
      (timeZoneOffset ? parseOffset(timeZoneOffset) : user.timeZoneOffSet) || 0,
    );
    const path = await prisma.learningPath.findFirst({
      where: {
        userId: user.id,
      },
      select: {
        type: true,
        id: true,
      },
    });
    if (timezone || timeZoneOffset) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          timezone,
          timeZoneOffSet: timeZoneOffset
            ? parseOffset(timeZoneOffset)
            : undefined,
        },
      });
    }
    const streak = await prisma.streak.findFirst({
      where: {
        createdAt: {
          gte: currentDateInGMT,
          lt: nextDateInGMT,
        },
        userId: user.id,
      },
    });
    return {
      token,
      user: { ...user, isStreakActive: streak ? true : false },
      path,
    };
  }

  async signup(body: SignupDTO) {
    const { email, password, name, timezone, timeZoneOffset } = body;
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
        timeZoneOffSet: timeZoneOffset
          ? parseOffset(timeZoneOffset)
          : undefined,
        timezone,
      },
      omit: {
        password: true,
      },
    });
    const token = sign({ id: newUser.id }, this.service.get('JWT_SECRET'));
    return {
      token,
      user: newUser,
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

  async hydrate(token: string, timezone: string, timeZoneOffSet: string) {
    try {
      const payload = verifyJWT(
        token.replace('Bearer ', ''),
        process.env.JWT_SECRET,
      ) as JwtPayload;
      const user = await prisma.user.findFirst({
        where: { id: payload.id },
        omit: { password: true },
        include: {
          _count: {
            select: { paths: true },
          },
        },
      });
      if (!user)
        throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
      if (timezone || timeZoneOffSet) {
        await prisma.user.update({
          where: { id: user.id },
          data: {
            timezone,
            timeZoneOffSet: timeZoneOffSet
              ? parseOffset(timeZoneOffSet)
              : undefined,
          },
        });
      }
      const { currentDateInGMT, nextDateInGMT } = generateTimestamps(
        (timeZoneOffSet ? parseOffset(timeZoneOffSet) : user.timeZoneOffSet) ||
          0,
      );

      const streak = await prisma.streak.findFirst({
        where: {
          createdAt: {
            gte: currentDateInGMT,
            lt: nextDateInGMT,
          },
          userId: user.id,
        },
      });
      const path = await prisma.learningPath.findFirst({
        where: { userId: user.id },
        select: {
          type: true,
          id: true,
        },
      });
      return { ...user, path, isStreakActive: streak ? true : false };
    } catch (e) {
      throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
    }
  }

  async updatePassword(body: UpdatePasswordDTO, userId: string) {
    const user = await prisma.user.findFirst({ where: { id: userId } });
    const isPasswordCorrect = await verify(user.password, body.currentPassword);
    if (!isPasswordCorrect)
      throw new HttpException(
        'Incorrect current password. Please try again',
        HttpStatus.UNAUTHORIZED,
      );
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        password: await hash(body.newPassword),
      },
    });
    return {
      id: updatedUser.id,
    };
  }
}
