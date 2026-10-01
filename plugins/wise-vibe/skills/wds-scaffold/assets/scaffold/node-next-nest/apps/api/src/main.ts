// {{PROJECT_NAME}} api — NestJS entrypoint. 설정은 env 주입(.env.local | .env.prod).
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.listen(Number(process.env.PORT ?? 4000), '0.0.0.0');
}
bootstrap();
