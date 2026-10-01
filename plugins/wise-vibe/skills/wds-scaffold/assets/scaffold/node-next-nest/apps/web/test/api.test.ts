import { describe, expect, it } from 'vitest';
import { apiBase } from '../lib/api';

describe('apiBase', () => {
  it('defaults to compose service', () => expect(apiBase({})).toBe('http://api:4000'));
  it('honours API_BASE', () => expect(apiBase({ API_BASE: 'http://x' })).toBe('http://x'));
});
