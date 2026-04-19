import { test, expect, Page } from "@playwright/test";

const timestamp = Date.now();
const testEmail = `playwright+${timestamp}@example.com`;
const testPassword = "Test1234!@#$";
const testFirstName = "Test";
const testLastName = "User";

/**
 * Log in via the customer login form.
 *
 * Magento's KnockoutJS marks the #pass field as "hidden" from Playwright's
 * perspective, so we click it to focus and use keyboard input instead of fill().
 */
async function login(page: Page, email: string, password: string) {
  await page.goto("/customer/account/login/");
  const loginForm = page.locator("#login-form");
  // With Varnish, the login page HTML is cached and the form_key hidden input
  // starts empty. Magento's form-key-provider.js populates it from the form_key
  // cookie asynchronously; submitting before that lands causes "Invalid form key".
  await expect(loginForm.locator('input[name="form_key"]')).not.toHaveValue("");
  await loginForm.locator("#email").fill(email);
  // Tab from the email field into the password field, then type the password.
  // We cannot use fill() on #pass because Magento's KnockoutJS renders it as
  // hidden from Playwright's perspective.
  await page.keyboard.press("Tab");
  await page.keyboard.type(password);
  await loginForm.getByRole("button", { name: /sign in/i }).click();
  await expect(page.locator(".block-dashboard-info")).toBeVisible({
    timeout: 30_000,
  });
}

test.describe("Customer registration and login", () => {
  test.describe.configure({ mode: "serial" });

  test("register a new customer", async ({ page }) => {
    await page.goto("/customer/account/create/");

    await page.locator("#firstname").fill(testFirstName);
    await page.locator("#lastname").fill(testLastName);
    await page.locator("#email_address").fill(testEmail);
    await page.locator("#password").fill(testPassword);
    await page.locator("#password-confirmation").fill(testPassword);

    await page.getByRole("button", { name: /create an account/i }).click();

    // After successful registration, Magento redirects to the account dashboard
    await expect(
      page
        .getByText(/thank you for registering/i)
        .or(page.locator(".block-dashboard-info"))
    ).toBeVisible({ timeout: 30_000 });
  });

  test("log out", async ({ page }) => {
    await login(page, testEmail, testPassword);

    // Navigate directly to the logout URL
    await page.goto("/customer/account/logout/");

    // Magento shows a "You are signed out" page
    await expect(
      page.getByRole("heading", { name: /signed out/i })
    ).toBeVisible({ timeout: 30_000 });
  });

  test("log back in", async ({ page }) => {
    await login(page, testEmail, testPassword);

    // Verify the name appears on the dashboard
    await expect(page.getByText(testFirstName)).toBeVisible();
  });
});
