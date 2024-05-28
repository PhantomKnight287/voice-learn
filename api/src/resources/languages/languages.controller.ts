import { Controller, Get } from '@nestjs/common';
import { LanguagesService } from './languages.service';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';

@Controller('languages')
@ApiTags('Languages')
export class LanguagesController {
  constructor(private readonly languagesService: LanguagesService) {}

  @ApiOperation({
    description: 'Get all languages available',
    summary: 'Get all languages available',
  })
  @ApiOkResponse({
    schema: {
      example: [
        {
          id: 'string',
          name: 'string',
          flagUrl: 'string',
        },
      ],
    },
  })
  @Get()
  listLanguages() {
    return this.languagesService.getLanguages();
  }
}
