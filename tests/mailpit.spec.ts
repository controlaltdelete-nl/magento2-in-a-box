import { test, expect, APIRequestContext } from "@playwright/test";

const baseURL = process.env.BASE_URL || "http://magento.test";

const mailpitUrl =
  process.env.MAILPIT_URL ||
  (() => {
    const url = new URL(baseURL);
    url.port = "8025";
    url.pathname = "/";
    return url.origin;
  })();

const timestamp = Date.now();
const testEmail = `mailpit+${timestamp}@example.com`;
const testPassword = "Test1234!@#$";

async function isMailpitReachable(request: APIRequestContext): Promise<boolean> {
  try {
    const response = await request.get(`${mailpitUrl}/readyz`);
    return response.ok();
  } catch {
    return false;
  }
}

async function countMessagesTo(
  request: APIRequestContext,
  email: string
): Promise<number> {
  const query = encodeURIComponent(`to:${email}`);
  const response = await request.get(`${mailpitUrl}/api/v1/search?query=${query}`);
  if (!response.ok()) {
    return 0;
  }
  const body = await response.json();
  return body.messages_count ?? body.messages?.length ?? 0;
}

test.describe("Mailpit captures transactional email", () => {
  test("the welcome email arrives in Mailpit after registration", async ({
    page,
    request,
  }) => {
    test.skip(
      !(await isMailpitReachable(request)),
      `Mailpit not reachable at ${mailpitUrl}; run the container with ENABLE_MAILPIT=true and -p 8025:8025`
    );

    await page.goto("/customer/account/create/");

    await page.locator("#firstname").fill("Mailpit");
    await page.locator("#lastname").fill("Tester");
    await page.locator("#email_address").fill(testEmail);
    await page.locator("#password").fill(testPassword);
    await page.locator("#password-confirmation").fill(testPassword);

    await page.getByRole("button", { name: /create an account/i }).click();

    await expect(
      page
        .getByText(/thank you for registering/i)
        .or(page.locator(".block-dashboard-info"))
    ).toBeVisible({ timeout: 30_000 });

    await expect
      .poll(() => countMessagesTo(request, testEmail), {
        timeout: 30_000,
        intervals: [1_000],
      })
      .toBeGreaterThan(0);
  });
});
