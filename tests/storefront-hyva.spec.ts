import { test, expect } from "@playwright/test";

test.describe("Hyva storefront", () => {
  test("homepage renders with the Hyva theme", async ({ page }) => {
    const response = await page.goto("/");
    expect(response?.status()).toBe(200);

    const html = await page.content();
    expect(html).toContain("/frontend/Hyva/");
    expect(await page.locator("[x-data]").count()).toBeGreaterThan(0);
  });

  test("customer login page falls back to the Luma theme", async ({ page }) => {
    const response = await page.goto("/customer/account/login");
    expect(response?.status()).toBe(200);

    const html = await page.content();
    expect(html).toContain("/frontend/Magento/luma/");
    await expect(page.locator("[x-data]")).toHaveCount(0);
  });

  test("cart page falls back to the Luma theme", async ({ page }) => {
    const response = await page.goto("/checkout/cart/");
    expect(response?.status()).toBe(200);

    const html = await page.content();
    expect(html).toContain("/frontend/Magento/luma/");
    await expect(page.locator("[x-data]")).toHaveCount(0);
  });
});
