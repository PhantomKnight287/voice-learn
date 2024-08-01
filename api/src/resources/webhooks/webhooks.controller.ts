import { Body, Controller, Get, Post, Response } from '@nestjs/common';
import { WebhooksService } from './webhooks.service';
import { Response as R } from 'express';

@Controller('webhooks')
export class WebhooksController {
  constructor(private readonly webhooksService: WebhooksService) {}

  @Get('google-play')
  async getReq() {
    return {
      message: 'Hello World',
      working: true,
    };
  }

  @Post('google-play')
  async handleGooglePlayEvent(@Response() res: R, @Body() data: any) {
    res.status(204).send();
    this.webhooksService.handleGooglePlayEvent(data);
  }

  @Post('app-store')
  handleAppStoreEvent(@Response() res: R, @Body() data: any) {
    res.status(204).send();
    this.webhooksService.handleAppStoreEvent(data);
  }
}
