import { Body, Controller, Get, Headers, HttpCode, Post } from '@nestjs/common';
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
  hydrate(@Headers('Authorization') token: string) {
    return this.authService.hydrate(token);
  }
}
