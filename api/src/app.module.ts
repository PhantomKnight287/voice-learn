import {
  MiddlewareConsumer,
  Module,
  NestModule,
  RequestMethod,
} from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './resources/auth/auth.module';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthMiddleware } from './middlewares/auth/auth.middleware';
import { S3Service } from './services/s3/s3.service';
import { LanguagesModule } from './resources/languages/languages.module';
import { OnboardingModule } from './resources/onboarding/onboarding.module';
import { GeminiService } from './services/gemini/gemini.service';
import { BullModule } from '@nestjs/bull';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { EventsModule } from './resources/events/events.module';
import { QueueService } from './services/queue/queue.service';
import { OnboardingQueueConsumer } from './consumers/onboarding.consumer';
import { LessonsModule } from './resources/lessons/lessons.module';
import { QuestionsModule } from './resources/questions/questions.module';
import { LivesModule } from './resources/lives/lives.module';
import { ScheduleModule } from '@nestjs/schedule';
import { CronService } from './services/cron/cron.service';
import { GenerationsModule } from './resources/generations/generations.module';
import { ProfileModule } from './resources/profile/profile.module';
import { LoggingMiddleware } from './middlewares/logging/logging.middleware';
import { APP_FILTER } from '@nestjs/core';
import { AllExceptionsFilter } from './filters/all/all.filter';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    LanguagesModule,
    OnboardingModule,
    BullModule.forRootAsync({
      inject: [ConfigService],
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        redis: {
          host: configService.getOrThrow('REDIS_HOST'),
          port: configService.get<number>('REDIS_PORT', 6379),
          password: configService.getOrThrow('REDIS_PASSWORD'),
        },
      }),
    }),
    EventEmitterModule.forRoot({
      verboseMemoryLeak: true,
      maxListeners: 10,
      ignoreErrors: false,
    }),
    ScheduleModule.forRoot(),
    EventsModule,
    LessonsModule,
    QuestionsModule,
    LivesModule,
    GenerationsModule,
    ProfileModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    S3Service,
    GeminiService,
    QueueService,
    OnboardingQueueConsumer,
    CronService,
    {
      provide: APP_FILTER,
      useClass: AllExceptionsFilter,
    },
  ],
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
        {
          method: RequestMethod.GET,
          path: '/v(.*)/',
        },
      )
      .forRoutes('*');

    consumer.apply(LoggingMiddleware).forRoutes('*');
  }
}
