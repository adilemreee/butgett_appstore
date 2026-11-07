# Budgett

iOS 26 için SwiftUI + SwiftData tabanlı, **tek renk (siyah–beyaz)** harcama takip uygulaması.
Anlam renkten değil; ağırlık, boyut ve gri tonlarından gelir. Yüzen cam tab bar dışında
her yüzey tek ve sakin bir kart stilini paylaşır.

## Gereksinimler

- Xcode 26.x, iOS 26.5 SDK
- Deployment target: iOS 26.5 · watchOS 26.0
- Bundle id: `adilemre.budgett`

Projeyi aç ve çalıştır:

```bash
open budgett.xcodeproj
```

## Mimari

Dosya sistemi senkronize klasör yapısı kullanılıyor; `budgett/` altına eklenen her Swift
dosyası otomatik olarak hedefe dahil olur.

```
budgett/                  Ana uygulama hedefi (dosya sistemi senkronize klasör)
  budgettApp.swift        @main + ModelContainer kurulumu
  App/                    RootView, özel cam tab bar, router, kilit ekranı
  Models/                 SwiftData şeması (Txn, SpendCategory, Wallet, BudgetPlan,
                          Recurrence, Goal), tohum + demo veri
  Core/                   Ayarlar, para/tarih yardımcıları, analiz motoru, bütçe motoru,
                          tekrar motoru, bildirimler, biyometri, dışa aktarım
  Design/                 Tema, Liquid Glass sarmalayıcıları, ortak bileşenler
  Features/
    Transactions/         Akış listesi, satırlar, filtre, işlem detayı
    Entry/                Hızlı giriş ekranı, hesap makinesi tuş takımı, kategori seçici
    Insights/             Grafik kartları, ısı haritası, kategori kırılımı
    Budgets/              Planlar sekmesi, bütçe kartları/göstergesi, düzenleyici
    Goals/                Hedefler, katkı ekranı
    Recurring/            Abonelik/tekrar yönetimi
    Wallets/, Settings/   Cüzdanlar, kategoriler, görünüm, para birimi, bildirim, veri
  Intents/                Siri / Kısayollar (harcama ekle, aylık toplam)
  Core/WidgetPublisher.swift  Snapshot üretip WidgetKit'i uyandırır
  Core/WatchSyncService.swift  Snapshot'ı WatchConnectivity ile saate yollar

Shared/                   ÜÇ hedefin de (budgett, widget, watch) üye olduğu klasör
  WidgetBridge.swift      App Group yolu + snapshot modeli + biçimlendirme

BudgettWidgets/           Widget uzantısı hedefi (BudgettWidgetsExtension)
  BudgettWidgetsBundle.swift
  SnapshotProvider.swift  Paylaşılan JSON'u okuyan TimelineProvider
  SpendingWidget.swift    small / medium / rectangular / inline
  BudgetGaugeWidget.swift small / circular
  RecentActivityWidget.swift  medium / large
  UpcomingBillsWidget.swift   small / medium / rectangular
  QuickAddControl.swift   Kontrol Merkezi butonu (ControlWidget)
  WidgetTheme.swift       Uzantıya özel çizim yardımcıları

BudgettWatch/             Apple Watch uygulaması hedefi (BudgettWatch)
  BudgettWatchApp.swift   @main + WindowGroup
  WatchHomeView.swift     Tek ekran: bugün, hafta çubukları, bütçe göstergesi,
                          son hareketler
  QuickEntryScreen.swift  Saatten hızlı gelir/gider kaydı (Digital Crown ile tutar)
  WatchTheme.swift        Saate özel monokrom çizim yardımcıları
  WatchSyncStore.swift    WatchConnectivity ile snapshot'ı alır, gelir/gider yollar
  Assets.xcassets/        AppIcon (grafit zemin + "b" monogramı) + AccentColor

budgett/AppIcon.icon      Icon Composer ikonu (tek katman: "b" monogramı + grafit zemin)

Supporting/               Info.plist parçaları (üretilen plist'e merge edilir)
  budgett-Info.plist      budgett:// URL şeması
  BudgettWidgets-Info.plist  NSExtension tanımı
```

Tasarım kararları:

- **Tutarlar** her zaman pozitif `Decimal` olarak saklanır; yön `kind` alanından türetilir.
- **Enum'lar** ham String olarak kalıcı yazılır, böylece şema ileriye dönük esnek kalır.
- **İlişkiler** yalnızca `Txn → SpendCategory` ve `Txn → Wallet` üzerinde tanımlıdır; bütçe,
  hedef ve tekrar kayıtları UUID string referansı tutar (CloudKit uyumu için).
- Tüm yüzeyler `Design/Glass.swift` içindeki tek karttan geçer; `Design/Theme.swift`
  paletin tamamıdır. Modellerdeki `colorHex` alanları veri uyumu için durur ama
  çizimde kullanılmaz — `color` her zaman `.primary` döner.
- Kategori/seri ayrımı `Palette.shade(index)` gri basamaklarıyla yapılır.

## Öne çıkan özellikler

| Alan | Neler var |
| --- | --- |
| Akış | Dönem gezgini (gün/hafta/ay/yıl/tümü), güne göre gruplu liste, arama, çok kriterli filtre, kaydırmalı sil/düzenle/kopyala/analiz dışı bırak, yaklaşan ödemeler |
| Giriş | Hesap makinesi tuş takımı (+ − × ÷), sık kullanılan kategori önerileri, tarih/saat, cüzdan, etiket, not, fiş fotoğrafı, tek dokunuşla tekrar eden yapma |
| Analiz | Dönem özeti + önceki döneme göre değişim, seçilebilir bar grafik + ortalama çizgisi, kategori kırılımı ve detayına inme |
| Planlar | Bütçeler (haftalık/aylık/yıllık, kapsam, devir, eşik uyarısı, günlük hak), birikim hedefleri, abonelik/tekrar yönetimi |
| Ayarlar | Açık/koyu/sistem, para birimi + gösterim, haftanın ilk günü, tuş takımı tipi, gelir takibi, kuruş, gizli mod, Face ID, bildirimler, CSV/JSON dışa aktarım, cüzdanlar, kategoriler |
| Sistem | Siri/Kısayollar, yerel bildirimler, widget'lar, Apple Watch uygulaması |

Sadeleştirme turunda bilinçli olarak çıkarılanlar: akıllı özet kartları, harcama ısı
haritası, "en çok harcadıkların" listesi, Analiz'deki varlık kartı (cüzdanlar Ayarlar'da
duruyor), renk seçiciler ve vurgu rengi temaları.

## Widget'lar

`Shared/` klasörü `budgett`, `BudgettWidgetsExtension` ve `BudgettWatch` hedefinin ortak
üyesidir; oraya koyduğun her dosya üç tarafta da derlenir. Ortak kod için tek yer orası.

Watch uygulaması da SwiftData deposuna **hiç dokunmaz**. App Group konteyneri her cihazda
ayrı bir dosya sistemi olduğu için telefonun yazdığı dosya saate kendiliğinden ulaşmaz;
uygulama snapshot'ı **WatchConnectivity** ile saate iter, saat de onu kendi Documents
dizinine kaydeder. Böylece saat ekranı telefonla her zaman aynı sayıları gösterir.

Widget'lar SwiftData deposuna **hiç dokunmaz**. Uygulama her veri değişiminde küçük bir
JSON özeti (`widget-snapshot.json`) App Group konteynerine yazar, uzantı onu okur. Bunun
üç faydası var: uzantı hafif kalır, ikinci bir CloudKit yığını kurulmaz ve ana veritabanı
bulunduğu yerde kalır (App Group'u sonradan açmak mevcut verini taşımaz).

| Widget | Boyutlar | İçerik |
| --- | --- | --- |
| Harcama | small, medium, rectangular, inline | Haftalık toplam, 7 günlük bar grafiği, ay kategorileri, hızlı ekle |
| Bütçe | small, circular | Yarım daire gösterge, kalan tutar, günlük hak, kalan gün |
| Son hareketler | medium, large | Aylık net + son işlemler + ekle butonu |
| Yaklaşan ödemeler | small, medium, rectangular | Sıradaki abonelik/ödemeler ve toplamı |
| Harcama ekle | Kontrol Merkezi / Kilit ekranı | Tek dokunuşla giriş ekranı (ControlWidget) |

Widget'a dokunmak `budgett://` derin bağlantısıyla ilgili sekmeyi ya da giriş ekranını açar.

### Kurulum: App Group (senin yapman gereken tek şey)

1. Xcode ▸ **budgett** hedefi ▸ Signing & Capabilities ▸ **+ Capability** ▸ App Groups ▸
   `group.adilemre.budgett` grubunu ekle/işaretle.
2. Aynısını **BudgettWidgetsExtension** hedefi için tekrarla.
3. Farklı bir grup kimliği kullanacaksan tek bir yeri güncelle:
   `budgett/Core/WidgetBridge.swift` ▸ `SharedStore.appGroupID`.

Durumu uygulama içinden görebilirsin: **Ayarlar ▸ Dışa aktar & yedek ▸ Widget**. Grup
bağlı değilse widget'lar örnek veriyle çizilir ve orada "Kurulu değil" yazar.

### iCloud / CloudKit

`budgett/budgett.entitlements` içinde CloudKit servisi ve `iCloud.adilemre.budgett`
container'ı tanımlı. Otomatik imzalama açık olduğu için Xcode ilk arşivde container'ı
geliştirici hesabına kaydeder.

Container listesi **boş bırakılırsa** App Store yüklemesi
`Invalid Code Signing Entitlements ... com.apple.developer.icloud-container-environment`
(hata 90046) ile reddedilir: Xcode export sırasında bu anahtarı boş değerle yazar.
CloudKit'i şimdilik istemiyorsan çözüm, anahtarı elle eklemek değil, Signing &
Capabilities altından iCloud yeteneğini tamamen kaldırmaktır.

Uygulama içindeki iCloud anahtarı varsayılan kapalı; açıldığında bir sonraki başlatmada
devreye girer. Container erişilemezse uygulama sessizce yerel depoya düşer, çökmez.

## Apple Watch

`BudgettWatch` tek hedeflik bir watchOS uygulamasıdır; iOS uygulamasının içine gömülür
(Embed Watch Content) ve `adilemre.budgett.watchkitapp` bundle kimliğini taşır. SwiftData'ya
bağlanmaz — telefon `Core/WatchSyncService.swift` ile snapshot'ı WatchConnectivity üzerinden
yollar, saat de `WatchSyncStore.swift` ile alıp yerel olarak saklar. Sonuç: saat ekranı
telefonla birebir aynı sayıları gösterir.

Tek, sakin bir ekran: bugünün harcaması, 7 günlük çubuk grafik, bütçe göstergesi
(kalan tutar + gün) ve son hareketler. Tasarım iOS uygulamasının monokrom dilini
tekrarlar: yalnızca `.primary`/`.secondary`, yuvarlak tipografi ve tek kart stili.
Gizli mod açıkken tutarlar `••••` olarak maskelenir; gelir takibi kapalıyken net satırlar gizlenir.

Sağ üstteki **+** ile hızlı kayıt açılır: Gider/Gelir seç, tutarı **Digital Crown** ile ayarla,
Kaydet'e bas. İstek WatchConnectivity ile telefona gider; telefon işlemi SwiftData'ya yazar,
snapshot'ı yeniler ve saati anında günceller. Telefon erişilemezse saat "Tekrar dene" gösterir.

### Senkron nasıl çalışır?

App Group konteyneri her cihazda **ayrı** olduğu için telefonun yazdığı `widget-snapshot.json`
saate kendiliğinden ulaşmaz. Bunun yerine:

1. Telefon, her veri değişiminde snapshot'ı widget'lara yazdıktan sonra `WatchSyncService`
   ile WatchConnectivity üzerinden saate iter (`updateApplicationContext`, "en son durum" kazanır).
2. Saat `WatchSyncStore` ile snapshot'ı alır, kendi Documents dizinine kaydeder ve ekranı tazeler.
3. Saatten gelen gelir/gider ise `sendMessage` ile anında telefona iletilir; telefon yazar,
   yeniden yayınlar ve başarı yanıtı döner.
4. Saat uygulaması kapalıyken gelen son snapshot, uygulama bir sonraki açılışta uygulanır.

Bunun için saatte **App Group gerektirmez**; ama `BudgettWatch.entitlements` içinde grup yazılı
bırakıldı (zararsız). Tek koşul: telefon ve saatin eşleşmiş olması ve telefon uygulamasının
en az bir kez açılıp snapshot üretmesi. Saat ilk açılışta veri bulamazsa "iPhone'da Budgett'ı aç"
boş durumunu gösterir.

## Sorun giderme

Proje açılmazsa `Supporting/project.pbxproj.widgetsiz-yedek` dosyası widget eklenmeden
önceki hâlin birebir kopyasıdır; `budgett.xcodeproj/project.pbxproj` üzerine kopyalayınca
proje widget'sız ama çalışır duruma döner.

## App Store

`AppStore/` klasöründe mağaza sayfası için hazır her şey var:

- `app-store-connect.md` — ad, altyazı, açıklama, anahtar kelimeler, gizlilik politikası
  metni, inceleme notu ve yüklemeden önceki kontrol listesi
- `ekran-goruntuleri-6.3/` — 1206 × 2622 px, başlıklı, doğrudan yüklenebilir
- `ham-ekran-goruntuleri/` — aynı ekranların başlıksız hâli

İkon `budgett/AppIcon.icon` içinde Icon Composer biçiminde duruyor; açık, koyu ve tonlu
görünümleri Xcode arşiv sırasında kendisi üretiyor, ayrıca 1024'lük PNG yüklemen gerekmiyor.
Eski PNG tabanlı ikon `Supporting/eski-ikon/AppIcon.appiconset` altında duruyor.

## Yerelleştirme

Arayüz Türkçe. Tarih ve ay adlarının da Türkçe gelmesi için proje geliştirme bölgesi
`tr` olarak ayarlandı (`CFBundleDevelopmentRegion`). Çok dilli yapmak istersen
`en.lproj` ekleyip metinleri String Catalog'a taşıman yeterli.
