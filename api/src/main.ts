import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';
import morgan from 'morgan';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import './constants';
import { errorSubject$ } from './constants';

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
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
    }),
  );
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('/docs/v1', app, document);
  if (process.env.LOGSTRAP_KEY && process.env.LOGSTRAP_PATH)
    errorSubject$.subscribe((payload) => {
      fetch(process.env.LOGSTRAP_PATH, {
        method: 'POST',
        body: JSON.stringify(payload),
        headers: {
          'X-API-KEY': process.env.LOGSTRAP_KEY,
          'content-type': 'application/json',
        },
      }).catch(() => {});
    });
  await app.listen(5000);
}
bootstrap();
