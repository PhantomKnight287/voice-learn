import { Controller, Get } from '@nestjs/common';
import { VoicesService } from './voices.service';
import { ApiHeader, ApiTags } from '@nestjs/swagger';

@Controller('voices')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
@ApiTags('Voices')
export class VoicesController {
  constructor(private readonly voicesService: VoicesService) {}

  @Get()
  listVoices() {
    return this.voicesService.listAllVoices();
  }
}
