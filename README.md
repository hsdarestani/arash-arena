# ARASH: Arena

یک بازی سه‌بعدی ساده و Mobile-first با Godot 4.7 برای اندروید.

## چیزی که الان ساخته شده

- نمای سه‌بعدی Top-down و محیط Low-poly
- کنترل لمسی با جوی‌استیک و دکمه حمله
- کنترل دسکتاپ با WASD و Space
- موج بی‌نهایت اسکلت‌ها و افزایش تدریجی سختی
- سیستم HP، امتیاز، Game Over و Restart
- محیط و مدل‌های fallback داخلی؛ بازی بدون اینترنت هم اجرا می‌شود
- دانلود خودکار مدل‌های CC0 شوالیه و اسکلت KayKit در اجرای اول
- کش کردن مدل‌ها در `user://cc0`
- تنظیمات سبک مناسب موبایل: GL Compatibility و ARM64

## اجرای سریع در ویندوز

1. Godot 4.7.1 را نصب یا نسخه portable را اجرا کن.
2. پوشه پروژه را با `Import` باز کن.
3. F6 یا F5 را بزن.

مدل‌های KayKit در اجرای اول دانلود می‌شوند. برای اینکه مدل‌ها داخل خود APK باشند، قبل از باز کردن پروژه این فایل را اجرا کن:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\download_cc0_assets.ps1
```

بعد پروژه را در Godot دوباره باز کن تا فایل‌های GLB Import شوند.

## خروجی APK

هر Push یا Pull Request، Workflow موجود در `.github/workflows/build-android.yml` را اجرا می‌کند. خروجی Debug APK در بخش Artifacts با نام `ARASH-Arena-Android` قرار می‌گیرد.

برای خروجی محلی:

1. داخل Godot از `Editor > Manage Export Templates` قالب‌های 4.7.1 را نصب کن.
2. Android SDK و OpenJDK را در `Editor Settings > Export > Android` معرفی کن.
3. از `Project > Export > Android > Export Project` خروجی بگیر.
4. فایل پیش‌فرض در `build/ARASH_Arena.apk` ذخیره می‌شود.

## کنترل‌ها

- موبایل: جوی‌استیک چپ برای حرکت، دکمه قرمز راست برای حمله
- دسکتاپ: WASD / کلیدهای جهت و Space
- بعد از باخت: دکمه `FIGHT AGAIN` یا کلید R

## لایسنس

کد پروژه MIT است. مدل‌های KayKit استفاده‌شده CC0 هستند و برای پروژه تجاری هم آزادند. جزئیات در `THIRD_PARTY_ASSETS.md` آمده است.
