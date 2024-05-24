import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';
import morgan from 'morgan';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { VersioningType } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(morgan('dev'), helmet());
  const config = new DocumentBuilder()
    .setTitle('Voice Learn')
    .setDescription('The Voice Learn Api')
    .setVersion('1.0')
    .build();

  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('/docs/v1', app, document);
  await app.listen(3000);
}
bootstrap();
