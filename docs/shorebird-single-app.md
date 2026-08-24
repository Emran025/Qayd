# Shorebird OTA for the single Qayd app

يستخدم Qayd Shorebird كتطبيق واحد فقط. لا توجد مدرسة أو tenant أو build matrix في هذه الآلية، ولا تُحقن أي قيم `SCHOOL_ID` أو `SCHOOL_CODE` أو `SCHOOL_NAME` في البناء.

ملف `shorebird.yaml` موجود في جذر المشروع، ويجب أن يحتوي على `app_id` الذي ينشئه Shorebird لحساب Qayd. قيمة `app_id` تعريف عام وليست سراً، لكن لا يجوز اختلاقها أو استخدام معرف تطبيق آخر. بعد تشغيل `shorebird init --display-name "Qayd"` بنجاح على جهاز مصادق عليه، انقل القيمة الناتجة إلى `shorebird.yaml` ثم راجع التغيير قبل commit. الملف مضبوط على `auto_update: false` حتى يتحكم Qayd في التحديث ويعرض للمستخدم حالة واضحة بدلاً من تنزيل صامت أثناء عمليات الإقلاع الحساسة.

أُضيفت حزمة `shorebird_code_push` وطبقات Domain/Application/Data/Presentation. يفحص `AppUpdateCubit` الحالة بعد ظهور authenticated Qayd shell ولا يحجب splash أو فتح قاعدة البيانات. إذا وجد patch يعرض Banner مترجماً، ويتيح تنزيله، ثم يوضح أن إغلاق التطبيق وفتحه مطلوبان لتفعيل النسخة. إذا لم يكن التطبيق مبنياً بواسطة Shorebird، أو لم يكن المحرك متاحاً على المنصة، تكون الحالة `unavailable` ولا يؤثر ذلك في تشغيل Qayd.

## سياسة CI

يعمل `.github/workflows/shorebird.yml` على تطبيق Qayd واحد فقط. عند تغيير Dart/Flutter دون تغيير native أو dependencies أو assets، ينفذ `shorebird patch android --release-version latest` وينشر إلى stable. أما تغييرات `android/` أو `ios/` أو `pubspec.yaml` أو `pubspec.lock` أو `assets/` أو `shorebird.yaml` فتتطلب `shorebird release android` كاملاً. هذا التصنيف مقصود لأن Shorebird لا ي patch native code أو تغييرات assets وفق قائمة التحقق الرسمية.

كل من patch وrelease يحتاج إلى Android signing material في runner. يُعاد استخدام نفس keystore الخاص بـGitHub Release، ولا يجوز إنشاء keystore جديد لكل patch.

## مفاتيح هذا المسار

| الاسم | النوع | الاستخدام |
|---|---|---|
| `SHOREBIRD_TOKEN` | GitHub Secret | مصادقة إنشاء release/patch من CI |
| `ANDROID_KEYSTORE_BASE64` | GitHub Secret | keystore release نفسه |
| `ANDROID_KEYSTORE_PASSWORD` | GitHub Secret | كلمة مرور keystore |
| `ANDROID_KEY_ALIAS` | GitHub Secret | alias المفتاح |
| `ANDROID_KEY_PASSWORD` | GitHub Secret | كلمة مرور المفتاح |
| `QAYD_API_URL` | GitHub Secret | عنوان API الذي يجب أن يطابق build الإنتاج |

لا يحتاج هذا workflow إلى `BUILD_API_PRIVATE_KEY` أو `BUILD_API_BASE_URL` أو أي secrets خاصة بالمدارس؛ أزيل منطقها عمداً. كما لا يحتاج إلى GitHub Variables. `GITHUB_TOKEN` تلقائي من GitHub ويُستخدم فقط لقراءة المستودع.

يجب إضافة `app_id` الحقيقي إلى `shorebird.yaml` قبل أول `shorebird release`. كما يجب إضافة secrets إلى GitHub Actions قبل تشغيل workflow. لا ترسل `SHOREBIRD_TOKEN` أو keystore أو كلمات المرور في المحادثة أو issues.

## مراجع

- [Shorebird Initialize](https://docs.shorebird.dev/code-push/initialize/)
- [Shorebird GitHub Integration](https://docs.shorebird.dev/code-push/ci/github/)
- [Shorebird Create a Patch](https://docs.shorebird.dev/code-push/patch/)
- [Shorebird Create a Release](https://docs.shorebird.dev/code-push/release/)
- [shorebird_code_push API](https://pub.dev/documentation/shorebird_code_push/latest/)
