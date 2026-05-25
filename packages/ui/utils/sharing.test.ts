import { afterEach, describe, expect, mock, test } from "bun:test";
import { createShortShareUrl } from "./sharing";

const originalFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = originalFetch;
});

describe("createShortShareUrl", () => {
  test("does not upload when no paste API is configured", async () => {
    const fetchMock = mock(async () => new Response("{}"));
    globalThis.fetch = fetchMock as unknown as typeof fetch;

    const result = await createShortShareUrl("private plan", []);

    expect(result).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
