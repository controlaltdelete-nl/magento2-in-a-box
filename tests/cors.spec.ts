import { test, expect } from "@playwright/test";

test.describe("CORS headers", () => {
  test("responses allow any origin", async ({ request }) => {
    const response = await request.get("/");

    expect(response.status()).toBe(200);
    expect(response.headers()["access-control-allow-origin"]).toBe("*");
  });

  test("preflight is answered without hitting Magento", async ({ request }) => {
    const response = await request.fetch("/", { method: "OPTIONS" });

    expect(response.status()).toBe(204);
    expect(response.headers()["access-control-allow-origin"]).toBe("*");
    expect(response.headers()["access-control-allow-methods"]).toBe("*");
    expect(response.headers()["access-control-allow-headers"]).toBe("*");
  });

  test("rest api responses allow any origin", async ({ request }) => {
    const response = await request.get("/rest/V1/directory/countries");

    expect(response.headers()["access-control-allow-origin"]).toBe("*");
  });
});
