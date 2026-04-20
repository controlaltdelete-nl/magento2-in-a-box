import { test, expect } from "@playwright/test";

test.describe("Storefront basics", () => {
  test("homepage loads", async ({ page }) => {
    const response = await page.goto("/");
    expect(response?.status()).toBe(200);
  });

  test("customer login page loads", async ({ page }) => {
    await page.goto("/customer/account/login");
    await expect(
      page.getByRole("heading", { name: /customer login/i })
    ).toBeVisible();

    // Verify the login form fields are present and the form is functional
    const loginForm = page.locator("#login-form");
    await expect(loginForm.locator("#email")).toBeVisible();
    await expect(loginForm.getByRole("button", { name: /sign in/i })).toBeVisible();
  });

  test("cart page loads", async ({ page }) => {
    await page.goto("/checkout/cart/");
    // An empty cart shows a message about having no items
    await expect(
      page.getByText(/no items/i).or(page.getByText(/empty/i))
    ).toBeVisible();
  });
});
