import { test, expect } from '@playwright/test'

test('application shell loads', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('body')).toBeVisible()
  await expect(page).toHaveTitle(/How|Rent|HTR/i)
})
