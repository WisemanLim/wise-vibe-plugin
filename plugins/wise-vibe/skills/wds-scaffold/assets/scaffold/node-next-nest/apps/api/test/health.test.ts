import { describe, expect, it } from 'vitest';
import { HealthController } from '../src/health.controller';

describe('HealthController', () => {
  it('returns ok', () => {
    expect(new HealthController().health().status).toBe('ok');
  });
});
