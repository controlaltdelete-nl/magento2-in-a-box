import { test, expect } from "@playwright/test";

test.describe("Hyva storefront", () => {
  test("homepage renders with the Hyva theme", async ({ page }) => {
    const response = await page.goto("/");
    expect(response?.status()).toBe(200);

    const html = await page.content();
    expect(html).toContain("/static/frontend/Hyva/default/");
    await expect(page.locator("html[x-data]")).toHaveCount(1);
  });

  test("customer login page renders with the Hyva theme", async ({ page }) => {
    const response = await page.goto("/customer/account/login");
    expect(response?.status()).toBe(200);

    const html = await page.content();
    expect(html).toContain("/static/frontend/Hyva/default/");
  });

  test("cart page falls back to the Luma checkout theme", async ({ page }) => {
    const response = await page.goto("/checkout/cart/");
    expect(response?.status()).toBe(200);

    const html = await page.content();
    expect(html).toContain("/static/frontend/Magento/luma/");
  });
});
