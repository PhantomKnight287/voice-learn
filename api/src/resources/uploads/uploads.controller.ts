import {
  Controller,
  Get,
  Param,
  Post,
  Query,
  Response,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { UploadsService } from './uploads.service';
import { ApiBody, ApiConsumes, ApiOperation } from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Response as R } from 'express';

@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post()
  @ApiOperation({})
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    description: 'File to upload',
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: {
        fileSize: 50 * 1024 * 1024,
      },
    }),
  )
  uploadFile(@UploadedFile() file: Express.Multer.File, @Auth() auth: User) {
    return this.uploadsService.uploadToPrivate(auth.id, file);
  }

  @Get(':id')
  async getUpload(
    @Query('chatId') chatId: string,
    @Query('token') token: string,
    @Param('id') id: string,
    @Response() res: R,
  ) {
    return this.uploadsService.redirectToPublicUrl(token, chatId, id, res);
  }

  @Post('public')
  @ApiOperation({})
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    description: 'File to upload',
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: {
        fileSize: 50 * 1024 * 1024,
      },
    }),
  )
  uploadToPublicUrl(
    @UploadedFile() file: Express.Multer.File,
    @Auth() auth: User,
  ) {
    return this.uploadsService.uploadToPublicBucket(auth.id, file);
  }
}
