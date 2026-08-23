# Qayd Android Release Deployment

هذا المشروع يبني APK Android موقّعاً من خلال `.github/workflows/build-release.yml` عند دفع Git tag بصيغة `v1.2.3` أو `v1.2.3+45`. لا تُحفظ مادة التوقيع أو كلمات المرور في Git؛ يقوم workflow بإنشاء ملفات signing مؤقتة داخل runner ثم ينتهي عمرها بانتهاء job.

## إعداد هوية التطبيق

قبل أول إصدار عام، يجب اختيار Android application ID نهائي وفريد، مثل `com.yourcompany.qayd`. لا تستخدم `com.example.qayd` في الإصدار العام؛ تغيير application ID بعد النشر ينشئ تطبيقاً مختلفاً ولا يُعد ترقية للتطبيق المنشور سابقاً.

أضف متغير Repository Variable باسم `QAYD_ANDROID_APPLICATION_ID`، وقيمته application ID النهائي. يتحقق workflow من الصيغة ويمررها إلى Gradle عبر `-PqaydApplicationId`.

## إنشاء Android release keystore

نفّذ الأمر التالي على جهاز آمن خارج المستودع، واستبدل القيم بمعلوماتك الفعلية:

```bash
keytool -genkeypair \
  -v \
  -keystore qayd-release.jks \
  -alias qayd-release \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000
```

احفظ نسخة offline مشفرة من ملف `qayd-release.jks`، وكلمات المرور، واسم alias. فقدان keystore أو تغيير alias/password بعد نشر التطبيق قد يمنع تحديث التطبيق المنشور.

حوّل نسخة keystore إلى Base64 على جهازك فقط، ثم ألصق الناتج مباشرة في GitHub Secret:

```bash
base64 --wrap=0 qayd-release.jks > qayd-release.jks.base64
```

لا ترفع `qayd-release.jks` أو `qayd-release.jks.base64` إلى Git أو إلى issue أو chat. قواعد `.gitignore` تمنع ملفات keystore و`android/key.properties` من التتبع.

## GitHub Secrets المطلوبة

| الاسم | النوع | مطلوب؟ | المحتوى |
|---|---|---:|---|
| `ANDROID_KEYSTORE_BASE64` | Repository Secret | نعم | محتوى Base64 الكامل لملف `qayd-release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Repository Secret | نعم | كلمة مرور keystore |
| `ANDROID_KEY_ALIAS` | Repository Secret | نعم | alias الذي أُنشئ به المفتاح |
| `ANDROID_KEY_PASSWORD` | Repository Secret | نعم | كلمة مرور المفتاح |
| `QAYD_API_URL` | Repository Secret | نعم للإصدار production | عنوان API الإنتاج مثل `https://api.example.com` |
| `REVERB_APP_KEY` | Repository Secret | اختياري | مفتاح WebSocket إذا كان مختلفاً عن default المضمن في التطبيق |
| `SENTRY_DSN` | Repository Secret | اختياري | DSN الخاص ببيئة Sentry، إذا كان Sentry مفعلاً |

القيم التالية ليست أسراراً تشفيرية، ولذلك يستخدمها workflow كـRepository Variables:

| الاسم | النوع | القيمة المعتادة |
|---|---|---|
| `QAYD_ANDROID_APPLICATION_ID` | Repository Variable | application ID النهائي، وليس `com.example.qayd` |
| `SENTRY_ENV` | Repository Variable | `production` |
| `SENTRY_RELEASE` | Repository Variable | اتركه فارغاً لاستخدام versionName أو حدده صراحةً |
| `SENTRY_DIST` | Repository Variable | اتركه فارغاً لاستخدام versionCode أو حدده صراحةً |
| `SENTRY_ENABLED` | Repository Variable | `true` فقط بعد ضبط DSN والتحقق من سياسة الخصوصية، وإلا `false` |

`GITHUB_TOKEN` لا يحتاج إلى إضافة يدوية؛ يوفره GitHub تلقائياً للـworkflow بصلاحية `contents: write` المطلوبة لإنشاء GitHub Release. لا تضع Personal Access Token في YAML أو Secrets لهذا الغرض.

## إنشاء إصدار

بعد ضبط القيم السابقة، ادفع tag annotated من فرع الإصدار:

```bash
git tag -a v1.0.0 -m "Qayd Android v1.0.0"
git push origin v1.0.0
```

ينشئ workflow ملفين في GitHub Release:

- `qayd-v1.0.0.apk`: الملف المرتبط بالإصدار.
- `qayd.apk`: الاسم الثابت المستخدم لرابط أحدث إصدار.

كما يرفع debug symbols لمدة 90 يوماً كـworkflow artifact. عند تفعيل obfuscation أو Sentry، احتفظ بهذه symbols لكل إصدار بما يتوافق مع سياسة الاحتفاظ المعتمدة.

## فحوصات ما قبل النشر

يجب التأكد من أن application ID النهائي، API production URL، توقيع keystore، سياسة الخصوصية، وصلاحيات Android مثل Camera وNotifications معتمدة قبل دفع tag. يجب تثبيت APK الناتج على جهاز اختبار، اختبار تسجيل الدخول والمزامنة وقاعدة البيانات المشفرة، اختبار barcode camera وfront/back switching، ثم التحقق من توقيع APK قبل التوزيع.

لا يثبت نجاح GitHub Actions وحده أن اختبار الكاميرا أو كل تدفقات التطبيق نجحت على جهاز فعلي. كما أن هذا workflow يبني APK وGitHub Release فقط؛ النشر إلى Google Play يحتاج لاحقاً إلى مسار منفصل يتضمن Google Play service-account JSON أو OIDC، وليس من الآمن إضافته قبل تحديد حساب Play Console وpackage ID النهائي.
