import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Post,
  Query,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { SignInDTO } from './dto/sign-in.dto';
import { SignupDTO } from './dto/signup.dto';
import {
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';
import { UpdatePasswordDTO } from './dto/update-password.dto';
import { ResetPasswordDTO } from './dto/reset-password.dto';
import { ResetPasswordSubmitDTO } from './dto/reset-password-submit.dto';

@Controller('auth')
@ApiTags('Authentication')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @ApiOperation({})
  @HttpCode(200)
  @ApiOkResponse({
    schema: {
      example: {
        token: 'string',
        user: {
          name: 'string',
          email: 'string',
          id: 'string',
          gems: 'number',
          updatedAt: 'ISO string',
          createdAt: 'ISO string',
        },
      },
    },
  })
  @ApiNotFoundResponse({
    schema: {
      example: {
        message: 'string',
      },
    },
  })
  @ApiUnauthorizedResponse({
    schema: {
      example: {
        message: 'string',
      },
    },
  })
  @Post('sign-in')
  login(@Body() body: SignInDTO) {
    return this.authService.signIn(body);
  }

  @ApiOperation({})
  @ApiCreatedResponse({
    schema: {
      example: {
        token: 'string',
        user: {
          name: 'string',
          email: 'string',
          id: 'string',
          gems: 'number',
          updatedAt: 'ISO string',
          createdAt: 'ISO string',
        },
      },
    },
  })
  @ApiConflictResponse({
    schema: {
      example: {
        message: 'string',
      },
    },
  })
  @ApiUnauthorizedResponse({
    schema: {
      example: {
        message: 'string',
      },
    },
  })
  @Post('sign-up')
  register(@Body() body: SignupDTO) {
    return this.authService.signup(body);
  }

  @ApiOperation({
    description: 'Get the user info from a token',
  })
  @ApiOkResponse({
    schema: {
      example: {
        id: 'string',
        name: 'string',
        email: 'string',
        createdAt: 'Date',
        updatedAt: 'Date',
        gems: 'number',
      },
    },
  })
  @ApiUnauthorizedResponse({
    schema: {
      example: {
        message: 'string',
      },
    },
  })
  @Get('hydrate')
  hydrate(
    @Headers('Authorization') token: string,
    @Query('timezone') timezone: string,
    @Query('timeZoneOffset') timeZoneOffset: string,
  ) {
    return this.authService.hydrate(token, timezone, timeZoneOffset);
  }

  @Post('password/update')
  updatePassword(@Auth() auth: User, @Body() body: UpdatePasswordDTO) {
    return this.authService.updatePassword(body, auth.id);
  }

  @Post('forgot-password/email')
  sendResetPasswordEmail(@Body() body: ResetPasswordDTO) {
    return this.authService.sendPasswordResetEmail(body);
  }

  @Post('forgot-password/submit')
  resetPassword(@Body() body: ResetPasswordSubmitDTO) {
    return this.authService.resetPassword(body);
  }
}
