import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  health() {
    return {
      status: 'ok',
      env: process.env.APP_ENV ?? 'local',
      db: { engine: process.env.DB_ENGINE ?? 'sqlite' },
    };
  }
}
