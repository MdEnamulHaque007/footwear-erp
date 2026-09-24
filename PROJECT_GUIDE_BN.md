# Footwear ERP — সম্পূর্ণ প্রজেক্ট গাইড (বাংলায়)

এই ডকুমেন্টটি পুরো প্রজেক্টের গঠন, আর্কিটেকচার এবং প্রতিটি লেয়ারের ভূমিকা বিস্তারিতভাবে ব্যাখ্যা করে।  
**কোনো কোড পরিবর্তন করা হয়নি** — শুধু প্রতিটি `.dart` ফাইলে বাংলা কমেন্ট যোগ করা হয়েছে যাতে যে কেউ পড়েই বুঝতে পারে।

---

## ১. প্রজেক্টের উদ্দেশ্য

এটি একটি **জুতার উৎপাদন ব্যবস্থাপনা ERP সফটওয়্যার**।  
মূল ওয়ার্কফ্লো:

```
Master LC → Purchase Order (PO) → Cutting → Sewing → Production/Lasting → FG Issue → Export
```

প্রতিটি ধাপে পরিমাণ (Quantity) চেইন ভ্যালিডেশন থাকে যাতে আগের ধাপের চেয়ে বেশি উৎপাদন না হয়।

---

## ২. টেকনোলজি স্ট্যাক

| প্রযুক্তি          | ব্যবহার                          |
|--------------------|----------------------------------|
| Flutter            | UI (Web + Mobile)                |
| Firebase Auth      | লগইন / ইউজার ম্যানেজমেন্ট        |
| Cloud Firestore    | মূল ডাটাবেস                      |
| Firebase Storage   | ফাইল আপলোড                       |
| BLoC               | স্টেট ম্যানেজমেন্ট               |
| GetIt              | Dependency Injection             |
| GoRouter           | নেভিগেশন ও রাউট গার্ড            |
| Hive               | লোকাল ক্যাশ                      |
| Clean Architecture | লেয়ার আলাদা রাখা                |

---

## ৩. ফোল্ডার স্ট্রাকচার (lib/)

```
lib/
├── main.dart                 ← অ্যাপের এন্ট্রি পয়েন্ট
├── firebase_options.dart     ← Firebase কনফিগ
├── injection/
│   └── dependency_injection.dart  ← সব DI রেজিস্ট্রেশন
├── core/                     ← সাধারণ জিনিস (থিম, কনস্ট্যান্ট, ইউটিলিটি, সার্ভিস)
├── domain/                   ← ব্যবসায়িক লজিক (Entity + UseCase + Repository Interface)
├── data/                     ← ডেটা অ্যাক্সেস (Model + Repository Implementation)
└── presentation/             ← UI (Screen + BLoC + Widget + Route)
```

### ৩.১ Domain লেয়ার
- **entities/** → বিশুদ্ধ ব্যবসায়িক অবজেক্ট (কোনো ফ্রেমওয়ার্ক নেই)
- **repositories/** → ইন্টারফেস (abstract)
- **usecases/** → একটি নির্দিষ্ট কাজ (যেমন: CreatePO, ValidateQuantity)

### ৩.২ Data লেয়ার
- **models/** → Firestore JSON ↔ Entity রূপান্তর
- **repositories/** → ইন্টারফেসের ইমপ্লিমেন্টেশন (Firestore কল)
- **datasources/** → রিমোট/লোকাল ডেটা সোর্স

### ৩.৩ Presentation লেয়ার
- **blocs/** → Event → State ম্যানেজমেন্ট
- **screens/** → পেজ / স্ক্রিন
- **widgets/** → পুনঃব্যবহারযোগ্য UI কম্পোনেন্ট
- **routes/** → GoRouter কনফিগ ও গার্ড

---

## ৪. প্রধান মডিউলসমূহ

1. **Authentication & User Management** — রোল ও পারমিশন ভিত্তিক অ্যাক্সেস
2. **Master LC** — লেটার অফ ক্রেডিট ম্যানেজমেন্ট
3. **Purchase Order (PO)** — মাল্টি-লাইন PO, LC এর সাথে ভ্যালিডেশন
4. **Cutting** — PO ভিত্তিক কাটিং এন্ট্রি
5. **Sewing** — কাটিং থেকে সেলাই
6. **Production / Lasting** — সেলাই থেকে প্রোডাকশন
7. **Issue (FG)** — ফিনিশড গুডস ইস্যু
8. **Export** — শিপমেন্ট / এক্সপোর্ট
9. **Dashboard & Reports** — সামারি ও রিপোর্ট
10. **Settings & Admin** — ব্যবসায়িক সেটিংস, রোল, ইউজার

---

## ৫. কিভাবে কোড পড়বেন

1. প্রথমে `lib/main.dart` পড়ুন — অ্যাপ কীভাবে স্টার্ট হয়।
2. তারপর `lib/injection/dependency_injection.dart` — কোন ক্লাস কোথায় রেজিস্টার।
3. যেকোনো মডিউল বুঝতে চাইলে এই ক্রমে যান:
   - `domain/entities/...`
   - `domain/repositories/i_...`
   - `domain/usecases/...`
   - `data/models/...`
   - `data/repositories/...`
   - `presentation/blocs/...`
   - `presentation/screens/...`

প্রতিটি ফাইলের উপরে বাংলা কমেন্ট আছে যা বলে দেয় ফাইলটি কী করে।

---

## ৬. নিরাপত্তা নোট

- `firestore.rules` ফাইলে রোল-ভিত্তিক অ্যাক্সেস কন্ট্রোল আছে।
- প্রোডাকশনে ডিপ্লয় করার আগে rules পর্যালোচনা করুন।

---

## ৭. কীভাবে রান করবেন

```bash
flutter pub get
flutterfire configure   # Firebase প্রজেক্ট কানেক্ট
flutter run -d chrome
```

---

**ডেভেলপার:** Md Enamul Haque  
**কমেন্ট যোগ করা হয়েছে:** যাতে যে কেউ বাংলায় পড়েই পুরো সিস্টেম বুঝতে পারে।
