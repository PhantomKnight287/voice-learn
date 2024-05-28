import {
  MiddlewareConsumer,
  Module,
  NestModule,
  RequestMethod,
} from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './resources/auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { AuthMiddleware } from './middlewares/auth/auth.middleware';
import { S3Service } from './services/s3/s3.service';
import { LanguagesModule } from './resources/languages/languages.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    LanguagesModule,
  ],
  controllers: [AppController],
  providers: [AppService, S3Service],
  exports: [S3Service],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .exclude(
        {
          method: RequestMethod.POST,
          path: '/v(.*)/auth/(.*)',
        },
        {
          method: RequestMethod.GET,
          path: `/v(.*)/languages/`,
        },
        {
          method: RequestMethod.GET,
          path: `/v(.*)/languages`,
        },
      )
      .forRoutes('*');
  }
}
